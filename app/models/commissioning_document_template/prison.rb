module CommissioningDocumentTemplate
  class Prison < CommissioningDocumentTemplate::Base
    def request_type
      'HMPS'
    end

    def context
      super.merge(
        addressee_location: data_request.location,
        aliases: kase.subject_aliases,
        date_range: data_request.request_dates,
        deadline: deadline(5.days),
      )
    end
  end
end
