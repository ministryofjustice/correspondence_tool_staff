class ResponseUploaderService
  attr_reader :kase, :current_user, :attachment_type, :result

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-redraft' - approver uploads a response for redrafting to kilo for amendments
  #
  def initialize(options = {})
    @case                    = options[:kase]
    @current_user            = options[:current_user]
    @action                  = options[:action]
    @uploaded_files          = options[:uploaded_files]
    @is_compliant            = options[:is_compliant]
    @upload_comment          = options[:upload_comment]
    @bypass_message          = options[:bypass_message]
    @bypass_further_approval = options[:bypass_further_approval]

    @result = nil
    @type = :response
    @uploader = S3Uploader.new(@case, @current_user)
  end

  def seed!(filepath)
    @uploader.add_file_to_case(filepath, @type)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  def upload!
    begin
      if @uploaded_files.blank?
        @result = :blank
        @attachments = []
      else
        @attachments = @uploader.process_files(@uploaded_files, @type)
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

  def transition_state(response_attachments)
    ActiveRecord::Base.transaction do
      @case.upload_comment = @upload_comment
      filenames = response_attachments.map(&:filename)

      case @action
      when 'upload', 'upload-flagged'
        @case.state_machine.add_responses!(acting_user: @current_user,
                                           acting_team: @case.responding_team,
                                           filenames: filenames,
                                           message: @case.upload_comment)
      when 'upload-approve'
        upload_approve(filenames)
        @case.log_compliance_date

      when 'upload-redraft'
        @case.state_machine.upload_response_and_return_for_redraft!(
                             acting_user: @current_user,
                             acting_team: @case.approving_teams.with_user(@current_user).first,
                             message: @case.upload_comment,
                             filenames: filenames
        )
        @case.log_compliance_date if @is_compliant
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
