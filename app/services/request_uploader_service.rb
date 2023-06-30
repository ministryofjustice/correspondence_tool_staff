class RequestUploaderService
  attr_reader :kase, :current_user, :error_message, :result

  REQUEST_TYPE = :request

  def initialize(kase:, current_user:, uploaded_files:, upload_comment:)
    @case                    = kase
    @current_user            = current_user
    @uploaded_files          = uploaded_files
    @upload_comment          = upload_comment

    @result = nil
    @uploader = S3Uploader.new(@case, @current_user)
    @error_message = ""
  end

  def upload!
    begin
      if @uploaded_files.blank?
        @result = :blank
        @attachments = []
      else
        @attachments = @uploader.process_files(@uploaded_files, REQUEST_TYPE)
        transition_state(@attachments)
        @result = :ok
      end
    rescue Aws::S3::Errors::ServiceError,
           ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotUnique => e
      @error_message = "Error processing uploaded files: #{e.message}"
      Rails.logger.error(@error_message)
      @result = :error
      @attachments = nil
    end

    @attachments
  end

private

  def transition_state(response_attachments)
    filenames = response_attachments.map(&:filename)
    if @upload_comment.present?
      @case.state_machine.add_message_to_case!(
        acting_user: @current_user,
        acting_team: @current_user.case_team(@case),
        filenames:,
        message: @upload_comment,
      )
    end
  end
end
