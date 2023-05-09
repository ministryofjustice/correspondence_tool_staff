module CommissioningDocumentTemplate
  class Probation < CommissioningDocumentTemplate::Base
    def request_type
      'Probation'
    end

    def default_data_required
      'All paper and electronic information'
    end

    def context
      super.merge(
        addressee_location: data_request.location,
        pnc: kase.other_subject_ids,
        crn: kase.case_reference_number,
        date_range: data_request.request_dates,
        deadline: deadline(5),
        data_required: data_request.data_required || default_data_required
      )
    end

    def recipient_emails
      ["BranstonRegistryRequests2@justice.gov.uk"]
    end
  end
end
