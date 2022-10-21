module DocumentTemplate
  class CrossBorder < DocumentTemplate::Base
    def template_name
      "cross_border.docx"
    end

    def context
      {
        dpa_reference: kase.case_reference_number,
        offender_name: kase.subject_full_name,
        date_of_birth: date_format(kase.date_of_birth),
        aliases: kase.subject_aliases,
        date: today,
        prison_numbers: kase.prison_number,
        deadline: deadline(5),
      }
    end
  end
end
