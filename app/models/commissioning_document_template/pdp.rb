module CommissioningDocumentTemplate
  class Pdp < CommissioningDocumentTemplate::Base
    def request_type
      'PDP'
    end

    def context
      super.merge(aliases: kase.subject_aliases)
    end
  end
end
