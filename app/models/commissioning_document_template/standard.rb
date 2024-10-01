module CommissioningDocumentTemplate
  class Standard < CommissioningDocumentTemplate::Base
    def request_type
      :Standard
    end

    def deadline
      calculate_deadline(5)
    end

    def request_info
      data_request_area.data_requests.map do |request|
        {
          request_type: I18n.t("helpers.label.data_request.request_type.#{request.request_type}"),
          request_type_note: request.request_type_note.presence,
          date_from: date_format(request.date_from),
          date_to: date_format(request.date_to),
        }
      end
    end

    def requests
      data_request_area.data_requests.map do |request|
        {
          request_type: I18n.t("helpers.label.data_request.request_type.#{request.request_type}"),
        }
      end
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        deadline:,
        request_info:,
        requests:,
      )
    end
  end
end
