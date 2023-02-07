class CommissioningDocumentUploaderService
  attr_reader :kase, :current_user, :error_message, :result

  REQUEST_TYPE = :commissioning_document

  def initialize(kase:, current_user:, commissioning_document:, uploaded_file:)
    @case = kase
    @commissioning_document = commissioning_document
    @current_user = current_user
    @uploaded_file = uploaded_file

    @result = nil
    @uploader = S3Uploader.new(@case, @current_user)
    @error_message = ''
  end

  def upload!
    begin
      if @uploaded_file.blank?
        @result = :blank
        @attachment = []
      else
        @attachment = @uploader.process_files(@uploaded_file, REQUEST_TYPE).first
        @commissioning_document.update(attachment: @attachment)
        @result = :ok
      end
    rescue Aws::S3::Errors::ServiceError,
           ActiveRecord::RecordInvalid,
           ActiveRecord::RecordNotUnique => err
      @error_message = "Error processing uploaded files: #{err.message}"
      Rails.logger.error(@error_message)
      @result = :error
      @attachment = nil
    end

    @attachment
  end
end
