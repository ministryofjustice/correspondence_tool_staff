module CommissioningDocumentTemplate
  class Telephone < CommissioningDocumentTemplate::Base
    def request_type
      :Tel_Recording
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
