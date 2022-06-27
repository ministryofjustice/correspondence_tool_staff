class ResponseUploaderService
  attr_reader :kase, :current_user, :attachment_type, :result

  RESPONSE_TYPE = :response

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-redraft' - approver uploads a response for redrafting to kilo for amendments
  #
  # This method already had 8 parameters - it was done with a params hash thus hiding it from rubocop
  #rubocop:disable Metrics/ParameterLists
  def initialize(kase:, current_user:, action:, uploaded_files:, is_compliant:,
                 upload_comment:, bypass_message:, bypass_further_approval:)
    @case                    = kase
    @current_user            = current_user
    @action                  = action
    @uploaded_files          = uploaded_files
    @is_compliant            = is_compliant
    @upload_comment          = upload_comment
    @bypass_message          = bypass_message
    @bypass_further_approval = bypass_further_approval

    @result = nil
    @uploader = S3Uploader.new(@case, @current_user)
  end
  #rubocop:enable Metrics/ParameterLists

  class << self
    # TODO: - this appears to be only used in tests
    def seed!(kase:, current_user:, filepath:)
      uploader = S3Uploader.new(kase, current_user)
      uploader.add_file_to_case(filepath, RESPONSE_TYPE)
      PdfMakerJob.perform_now(kase.attachments.first.id)
    end
  end

  def upload!
    begin
      if @uploaded_files.blank?
        @result = :blank
        @attachments = []
      else
        @attachments = @uploader.process_files(@uploaded_files, RESPONSE_TYPE)
        transition_state(@attachments)
        @result = :ok
      end
    rescue Aws::S3::Errors::ServiceError,
           ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotUnique => err
      Rails.logger.error("Error processing uploaded files: #{err.message}")
      @result = :error
      @attachments = nil
    end

    notify_next_approver if @result == :ok && @action == 'upload-approve'
    @attachments
  end

  private

  # When approving, always log compliance date because it must be
  # when asking for a re-draft, log compliance date if it is compliant
  # other cases are the responder uploading so it's obvious that compliance isn't yet decided.
  # so the date cannot be recorded (yet)
  def transition_state(response_attachments)
    ActiveRecord::Base.transaction do
      @case.upload_comment = @upload_comment
      filenames = response_attachments.map(&:filename)

      case @action
      when 'upload', 'upload-flagged'
        @case.state_machine.add_responses!(acting_user: @current_user,
                                           acting_team: @current_user.case_team_for_event(@case, 'add_responses'),
                                           filenames: filenames,
                                           message: @case.upload_comment)
      when 'upload-approve'
        upload_approve(filenames)
        @case.log_compliance_date!
      when 'upload-redraft'
        @case.state_machine.upload_response_and_return_for_redraft!(
                             acting_user: @current_user,
                             acting_team: @case.approving_teams.with_user(@current_user).first,
                             message: @case.upload_comment,
                             filenames: filenames
        )
        @case.log_compliance_date! if @is_compliant
      else
        raise "Unexpected action parameter: '#{@action}'"
      end
    end
  end

  def upload_approve(filenames)
    if @bypass_further_approval
      bypass_further_approvals(filenames)
    else
      approve_and_progress_as_normal(filenames)
    end
  end

  def bypass_further_approvals(filenames)
    further_approval_assignments.each { |asgmt| asgmt.bypassed! }
    @case.state_machine.upload_response_approve_and_bypass!(
                        acting_user: @current_user,
                        acting_team: @case.approving_teams.with_user(@current_user).first,
                        filenames: filenames,
                        message: combined_message)
  end

  def further_approval_assignments
    @case.approver_assignments - @case.approver_assignments.for_team(BusinessUnit.dacu_disclosure)
  end

  def combined_message
    msg = "Bypass Reason: #{@bypass_message}"
    if @case.upload_comment.present?
      msg += "<br/><br/>File upload comment: #{@case.upload_comment}"
    end
    msg.html_safe
  end

  def approve_and_progress_as_normal(filenames)
    @case.state_machine.upload_response_and_approve!(
      acting_user: @current_user,
      acting_team: @case.approving_teams.with_user(@current_user).first,
      filenames: filenames,
      message: @case.upload_comment
    )
  end

  def notify_next_approver
    if @case.current_state
           .in?(%w( pending_press_office_clearance pending_private_office_clearance ))

      current_info = CurrentTeamAndUserService.new(@case)
      assignment = @case.approver_assignments
                       .for_team(current_info.team)
                       .first

      ActionNotificationsMailer
          .ready_for_press_or_private_review(assignment)
          .deliver_later
    end
  end
end
