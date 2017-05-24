class ResponseUploaderService

  attr_reader :result

  def initialize(kase, current_user, params)
    @case = kase
    @current_user = current_user
    @params = params
    @result = nil
  end

  def upload!
    if @params[:uploaded_files].blank?
      @result = :blank
    else
      process_files
    end
  end

  def seed!
    key = "#{@case.attachments_dir('responses')}/eon.pdf"
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(key)
    uploads_object.upload_file(File.join(Rails.root, 'spec', 'fixtures', 'eon.pdf'))
    @case.attachments << CaseAttachment.new(type: 'response', key: key)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  private

  def response_attachments
    @response_attachments ||= @params[:uploaded_files].reject(&:blank?).map do |uploads_key|
      move_uploaded_response(uploads_key)
      CaseAttachment.find_or_initialize_by(
        type: 'response',
        key: response_destination_key(uploads_key)
      )
    end
  end

  def process_files
    if response_attachments.all?(&:valid?)
      response_attachments.select(&:persisted?).each(&:touch)
      if @case.requires_clearance?
        @case.add_response_to_flagged_case(@current_user, response_attachments)
      else
        @case.add_responses(@current_user, response_attachments)
      end
      remove_leftover_upload_files
      Rails.logger.warn "QUEUEING PDF MAKER JOB"
      response_attachments.each { |ra| PdfMakerJob.perform_later(ra.id) }
      @result = :ok
    else
      @result = :error
    end
  end


  def move_uploaded_response(uploads_key)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(uploads_key)
    uploads_object.move_to response_destination_path(uploads_key)
  end

  def response_destination_path(uploads_key)
    "#{Settings.case_uploads_s3_bucket}/#{response_destination_key(uploads_key)}"
  end

  def response_destination_key(uploads_key)
    "#{@case.attachments_dir('responses')}/#{File.basename(uploads_key)}"
  end

  def remove_leftover_upload_files
    prefix = "uploads/#{@case.id}"
    CASE_UPLOADS_S3_BUCKET.objects(prefix: prefix).each do |object|
      object.delete
    end
  end
end
