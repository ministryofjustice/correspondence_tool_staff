class PdfMakerJob < ApplicationJob

  queue_as :pdf_maker


  def self.perform_with_delay(attachment_id, retry_count)
    set(wait: Settings.s3_upload_retry_delay_minutes.minutes).perform_later(attachment_id, retry_count)
  end

  def perform(attachment_id, retry_count = 0)
    begin
      attachment = CaseAttachment.find attachment_id
      attachment.make_preview(retry_count)
    rescue StandardError => err
      message = "PdfMakerJob Error creating Preview for attachment #{attachment_id}"
      Rails.logger.error "#{message}: #{err.class} - #{err.message}"
      attachment.preview_key = nil unless attachment.nil?
    end
  end
end
