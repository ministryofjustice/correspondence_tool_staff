module CommissioningDocumentTemplate
  class Pdp < CommissioningDocumentTemplate::Base
    def request_type
      :PDP
    end

    def deadline
      nil
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        date_range: data_request.request_dates,
        )
    end
  end
end
