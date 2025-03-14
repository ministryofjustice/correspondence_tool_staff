module CommissioningDocumentTemplate
  class Probation < CommissioningDocumentTemplate::Base
    def request_type
      :Probation
    end

    def default_data_required
      "All paper and electronic information"
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        pnc: kase.other_subject_ids,
        crn: kase.case_reference_number,
        date_range: data_request_area.request_dates,
        data_required: data_request_area.data_requests.first&.decorate&.data_required || default_data_required,
      )
    end
  end
end
