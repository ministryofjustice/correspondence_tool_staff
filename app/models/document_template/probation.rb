module DocumentTemplate
  class Probation < DocumentTemplate::Base
    def context
      super.merge(
        {
          deadline: deadline(5),
          pnc: kase.other_subject_ids,
          crn: kase.case_reference_number
        }
      )
    end
  end
end
