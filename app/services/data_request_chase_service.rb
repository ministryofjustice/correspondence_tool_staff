class DataRequestChaseService
  def self.call
    DataRequestArea.where(id: DataRequestArea.sent_and_in_progress_ids).find_each do |dra|
      if dra.chase_due?
        service = CommissioningDocumentEmailService.new(data_request_area: dra, commissioning_document: dra.commissioning_document, current_user: dra.kase.creator)
        service.send_chase!(dra.next_chase_type)
      end
    end
  end
end
