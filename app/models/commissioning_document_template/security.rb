module CommissioningDocumentTemplate
  class Security < CommissioningDocumentTemplate::Base
    def request_type
      :Security
    end

    def request_info
      data_request_area.data_requests.in_progress.map do |request|
        {
          request_type: I18n.t("helpers.label.data_request.request_type.#{request.request_type}"),
          request_type_note: request.request_type_note,
          date_from: date_format(request.date_from),
          date_to: date_format(request.date_to),
        }
      end
    end

    def requests
      data_request_area.data_requests.in_progress.map do |request|
        {
          request_type: I18n.t("helpers.label.data_request.request_type.#{request.request_type}"),
        }
      end
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        aliases: kase.subject_aliases,
        crn: kase.case_reference_number,
        pnc: kase.other_subject_ids,
        request_info:,
        requests:,
      )
    end
  end
end
