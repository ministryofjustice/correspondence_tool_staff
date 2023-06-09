module CommissioningDocumentTemplate
  class CatA < CommissioningDocumentTemplate::Base
    def request_type
      'CATA'
    end

    def deadline
      calculate_deadline(5)
    end

    def context
      super.merge(
        addressee_location: data_request.data_request_name,
        date_range: data_request.request_dates.capitalize,
        deadline: deadline
      )
    end
  end
end
