class DataRequestChaseService
  def self.call(dryrun: true)
    Rails.logger.info("Chases due:") if dryrun
    DataRequestArea.where(id: DataRequestArea.sent_and_in_progress_ids).find_each do |dra|
      if dra.chase_due?
        if dryrun
          Rails.logger.info("Case ID: #{dra.case_id} Data Request Area ID: #{dra.id}")
        else
          service = CommissioningDocumentEmailService.new(data_request_area: dra, commissioning_document: dra.commissioning_document, current_user: dra.kase.creator)
          service.send_chase!(dra.next_chase_type)
        end
      end
    end
  end
end
