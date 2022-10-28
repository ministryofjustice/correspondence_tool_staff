module CommissioningDocumentTemplate
  class CrossBorder < CommissioningDocumentTemplate::Base
    def request_type
      "TX"
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        deadline: deadline(5),
      )
    end
  end
end
