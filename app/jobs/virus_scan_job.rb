class VirusScanJob < ApplicationJob
  queue_as :virus_scan

  def perform(attachment_id)
    RavenContextProvider.set_context
    attachment = CaseAttachment.find attachment_id
    attachment.scan_for_virus
  end
end
