module CommissioningDocumentTemplate
  class Probation < CommissioningDocumentTemplate::Base
    def context
      super.merge(
        pnc: kase.other_subject_ids,
        crn: kase.case_reference_number,
        deadline: deadline(5),
      )
    end
  end
end
