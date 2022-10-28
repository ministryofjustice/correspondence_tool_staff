module CommissioningDocumentTemplate
  class Mappa < CommissioningDocumentTemplate::Base
    def context
      super.merge(
        aliases: kase.subject_aliases,
        pnc: kase.other_subject_ids,
        deadline: deadline(20),
      )
    end
  end
end
