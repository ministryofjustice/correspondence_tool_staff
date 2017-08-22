class ResponseUploaderService
  attr_reader :kase, :current_user, :attachment_type, :result

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-redraft' - approver uploads a response for redrafting to kilo for amendments
  #
  def initialize(kase, current_user, params, action_params)
    @case = kase
    @current_user = current_user
    @params = params
    @uploaded_files = params[:uploaded_files]
    @result = nil
    @action = action_params
    @type = :response
    @uploader = S3Uploader.new(@case, @current_user)
  end

  def seed!(filepath)
    @uploader.add_file_to_case(filepath, @type)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  def upload!
    if @uploaded_files.blank?
      @result = :blank
    else
      attachments = @uploader.process_files(@uploaded_files, @type)
      transition_state(attachments)
      @result = :ok
      attachments
    end
  rescue Aws::S3::Errors::ServiceError,
         ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotUnique => err
    Rails.logger.error("Error processing uploaded files: #{err.message}")
    @result = :error
  end

  private

  def transition_state(response_attachments)
    @case.upload_comment = @params[:upload_comment]
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
    when 'upload-redraft'
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
