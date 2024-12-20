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
          request_type_note: request.request_type_note,
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

    def request_additional_info
      additional_info = {
        "security_records" => "Please provide the unredacted security data requested (including all attachments linked to Mercury) as a Microsoft Word document and follow the Mercury Dissemination Guidance.\n",
        "cctv" => "When providing the footage please supply an up-to-date photograph of the data subject and confirm the data you are sending us contains that same person. We cannot proceed without you verifying this.\nIf you have access to a Teams channel, please send the footage in MP4 format where possible.\n",
        "bwcf" => "When providing the footage please supply an up-to-date photograph of the data subject and confirm the data you are sending us contains that same person. We cannot proceed without you verifying this.\nIf you have access to a Teams channel, please send the footage in MP4 format where possible.\n",
        "pdp" => "All CAT A files and series 6 subs (Cross Border Transfer files).\n",
        "telephone_recordings" => "If you have a transcript, please send this at the same time as the audio calls. If you do not have one we do not require you to create one.\n",
      }

      data_request_area.data_requests.map { |request|
        additional_info[request.request_type] || ""
      }.uniq.join("\n")
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        aliases: kase.subject_aliases,
        deadline:,
        pnc: kase.other_subject_ids,
        request_info:,
        requests:,
        request_additional_info:,
        crn: kase.case_reference_number,
      )
    end
  end
end
