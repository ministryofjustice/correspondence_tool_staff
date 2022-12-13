module CommissioningDocumentTemplate
  class CrossBorder < CommissioningDocumentTemplate::Base
    def request_type
      'TX'
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        date_range: data_request.request_dates.capitalize,
        deadline: deadline(5.days),
      )
    end
  end
end
