module CommissioningDocumentTemplate
  class CrossBorder < CommissioningDocumentTemplate::Base
    def context
      super.merge(
        aliases: kase.subject_aliases,
        deadline: deadline(5),
      )
    end
  end
end
