module CommissioningDocumentTemplate
  class CatA < CommissioningDocumentTemplate::Base
    def request_type
      'CATA'
    end

    def context
      super.merge(
        date_range: data_request.request_dates.capitalize,
        deadline: deadline(5)
      )
    end
  end
end
