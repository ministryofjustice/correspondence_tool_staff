module CommissioningDocumentTemplate
  class Mappa < CommissioningDocumentTemplate::Base
    def request_type
      :MAPPA
    end

    def deadline
      calculate_deadline(20)
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        pnc: kase.other_subject_ids,
        date_range: data_requests_area.request_dates,
        deadline:,
      )
    end
  end
end
