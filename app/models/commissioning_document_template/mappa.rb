module CommissioningDocumentTemplate
  class Mappa < CommissioningDocumentTemplate::Base
    def request_type
      :MAPPA
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        pnc: kase.other_subject_ids,
        date_range: data_request_area.request_dates,
      )
    end
  end
end
