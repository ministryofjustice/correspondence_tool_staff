module CommissioningDocumentTemplate
  class Standard < CommissioningDocumentTemplate::Base
    def request_type
      :Standard
    end

    def deadline
      calculate_deadline(5)
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        # date_range: data_request.request_dates.capitalize,
        deadline:,
        )
    end
  end
end
