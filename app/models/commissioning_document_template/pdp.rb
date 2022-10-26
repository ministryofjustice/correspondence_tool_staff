module CommissioningDocumentTemplate
  class Pdp < CommissioningDocumentTemplate::Base
    def context
      super.merge(aliases: kase.subject_aliases)
    end
  end
end
