module CommissioningDocumentTemplate
  class Cctv < CommissioningDocumentTemplate::Base
    def request_type
      :CCTV
    end

    def context
      super.merge(
        addressee_location: data_request_area.location,
        aliases: kase.subject_aliases,
        deadline:,
      )
    end
  end
end
