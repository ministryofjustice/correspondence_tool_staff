module DocumentTemplate
  class CatA < DocumentTemplate::Base
    def template_name
      "cat_a.docx"
    end

    def context
      {
        dpa_reference: kase.case_reference_number,
        offender_name: kase.subject_full_name,
        date_of_birth: date_format(kase.date_of_birth),
        date: today,
        prison_numbers: kase.prison_number,
        deadline: deadline(5),
      }
    end
  end
end
