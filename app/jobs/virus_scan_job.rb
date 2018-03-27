class VirusScanJob < ApplicationJob
  queue_as :virus_scan

  # def perform(attachment_id)
  # end
end
