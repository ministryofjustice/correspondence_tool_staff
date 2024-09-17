module CommissioningDocumentTemplate
  class Mappa < CommissioningDocumentTemplate::Base
    def request_type
      :MAPPA
    end

    def deadline
      calculate_deadline(20)
    end

    def context
      data_requests_dates = data_request_area.data_requests.decorate.map do |request|
        request_data = request.request_dates if request.request_dates.present?
        request_data
      end.join("\n")

      super.merge(
        aliases: kase.subject_aliases,
        pnc: kase.other_subject_ids,
        date_range: data_requests_dates,
        deadline:,
        )
    end
  end
end
