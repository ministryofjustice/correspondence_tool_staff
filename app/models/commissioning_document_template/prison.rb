module CommissioningDocumentTemplate
  class Prison < CommissioningDocumentTemplate::Base
    def request_type
      :HMPS
    end

    def default_data_required
      "All paper & electronic information including Security"
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
        data_required: data_request.data_required || default_data_required,
        )
    end
  end
end
