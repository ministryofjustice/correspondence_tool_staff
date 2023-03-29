module CommissioningDocumentTemplate
  class Probation < CommissioningDocumentTemplate::Base
    def request_type
      'Probation'
    end

    def context
      super.merge(
        addressee_location: data_request.location,
        pnc: kase.other_subject_ids,
        crn: kase.case_reference_number,
        date_range: data_request.request_dates,
        deadline: deadline(5),
      )
    end
  end
end
