class ResponseUploaderService
  include UploaderService

  attr_reader :kase, :current_user, :upload_group, :attachment_type

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-revert' - approer uploads a response and reverts to kilo for amendments
  #
  def initialize(kase, current_user, params, action_params)
    @case = kase
    @current_user = current_user
    @params = params
    @uploaded_files = params[:uploaded_files]
    @result = nil
    @action = action_params
    @upload_group = create_upload_group
    @type = :response
  end

  def seed!
    key = "#{@case.attachments_dir('responses', @upload_group)}/eon.pdf"
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(key)
    uploads_object.upload_file(File.join(Rails.root, 'spec', 'fixtures', 'eon.pdf'))
    @case.attachments << CaseAttachment.new(type: 'response', key: key)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  def upload!
    if @uploaded_files.blank?
      @result = :blank
    else
      attachments = process_files(@uploaded_files, @type)
      transition_state(attachments)
      @result = :ok
      attachments
    end
  rescue => err
    Rails.logger.error("Error processing uploaded files: #{err.message}")
    @result = :error
  end

  private

  def transition_state(response_attachments)
    filenames = response_attachments.map(&:filename)
    case @action
    when 'upload'
      @case.state_machine.add_responses!(@current_user, @case.responding_team, filenames)
    when 'upload-flagged'
      @case.state_machine.add_response_to_flagged_case!(@current_user, @case.responding_team, filenames)
    when 'upload-approve'
      @case.state_machine.upload_response_and_approve!(
        @current_user,
        @case.approving_teams.with_user(@current_user).first,
        filenames
      )
    when 'upload-revert'
      @case.state_machine.upload_response_and_return_for_redraft!(
                           @current_user,
                           @case.approving_teams.with_user(@current_user).first,
                           filenames
      )
    else
      raise "Unexpected action parameter: '#{@action}'"
    end
  end
end
