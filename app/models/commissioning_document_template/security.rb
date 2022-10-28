module CommissioningDocumentTemplate
  class Security < CommissioningDocumentTemplate::Base
    def request_type
      "Security"
    end

    def context
      super.merge(
        addressee_location: data_request.location,
        aliases: kase.subject_aliases,
        deadline: deadline(5),
      )
    end
  end
end
