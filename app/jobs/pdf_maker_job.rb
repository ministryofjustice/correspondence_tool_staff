class PdfMakerJob < ApplicationJob

  queue_as :pdf_maker

  def perform(attachment_id, retry_count = 0)
    SentryContextProvider.set_context
    attachment = CaseAttachment.find attachment_id
    attachment.make_preview(retry_count)
  end
end
