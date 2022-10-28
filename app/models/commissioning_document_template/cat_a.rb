module CommissioningDocumentTemplate
  class CatA < CommissioningDocumentTemplate::Base
    def context
      super.merge(deadline: deadline(5))
    end
  end
end
