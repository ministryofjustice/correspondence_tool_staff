module DocumentTemplate
  class MAPPA < DocumentTemplate::Base
    def template_name
      "mappa.docx"
    end

    def context
      {
        dpa_reference: kase.case_reference_number,
        offender_name: kase.subject_full_name,
        date_of_birth: date_format(kase.date_of_birth),
        aliases: kase.subject_aliases,
        date: today,
        prison_numbers: kase.prison_number,
        pnc: kase.other_subject_ids,
        deadline: deadline(20),
      }
    end
  end
end
