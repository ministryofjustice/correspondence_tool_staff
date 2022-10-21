module DocumentTemplate
  class Prison < DocumentTemplate::Base
    def template_name
      "prison.docx"
    end

    def context
      {
        addressee_location: data_request.location,
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
