module CommissioningDocumentTemplate
  class CrossBorder < CommissioningDocumentTemplate::Base
    def request_type
      "TX"
    end

    def deadline
      calculate_deadline(5)
    end

    def context
      super.merge(
        aliases: kase.subject_aliases,
        date_range: data_request.request_dates.capitalize,
        deadline:,
      )
    end
  end
end
