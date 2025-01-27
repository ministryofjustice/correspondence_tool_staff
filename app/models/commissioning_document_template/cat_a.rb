module CommissioningDocumentTemplate
  class CatA < CommissioningDocumentTemplate::Base
    def request_type
      :CATA
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        date_range: data_request_area.request_dates.capitalize,
        deadline:,
      )
    end
  end
end
