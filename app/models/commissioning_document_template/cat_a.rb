module CommissioningDocumentTemplate
  class CatA < CommissioningDocumentTemplate::Base
    def request_type
      'CATA'
    end

    def context
      super.merge(deadline: deadline(5))
    end
  end
end
