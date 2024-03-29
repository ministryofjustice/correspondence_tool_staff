module CommissioningDocumentTemplate
  class Security < CommissioningDocumentTemplate::Base
    def request_type
      "Security"
    end

    def deadline
      calculate_deadline(5)
    end

    def context
      super.merge(
        addressee_location: data_request.location,
        aliases: kase.subject_aliases,
        date_range: data_request.request_dates,
        deadline:,
      )
    end
  end
end
