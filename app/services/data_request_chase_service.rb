class DataRequestChaseService
  def call
    DataRequestArea.find_each(sent_and_in_progress_ids) do |dra|
      if dra.next_chase_date == Date.current
        service = CommissioningDocumentEmailService.new(data_request_area: dra, commissioning_document: dra.commissioning_document)
        service.send_chase!(dra.next_chase_type)
      end
    end
  end

  def sent_and_in_progress_ids
    sent_data_request_areas = CommissioningDocument.where(sent: true).pluck(:data_request_area_id)
    in_progress_data_request_areas = DataRequest.in_progress.pluck(:data_request_area_id)
    sent_data_request_areas.intersection(in_progress_data_request_areas)
  end
end
