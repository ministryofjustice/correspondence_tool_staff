module CommissioningDocumentTemplate
  class Prison < CommissioningDocumentTemplate::Base
    def request_type
      :HMPS
    end

    def default_data_required
      "All paper & electronic information including Security"
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        aliases: kase.subject_aliases,
        date_range: data_request_area.request_dates,
        data_required: data_request_area.data_requests.first&.decorate&.data_required || default_data_required,
      )
    end
  end
end
