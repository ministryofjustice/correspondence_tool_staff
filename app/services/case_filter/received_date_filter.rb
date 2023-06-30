module CaseFilter
  class ReceivedDateFilter < CaseDateRangeFilterBase
    def self.date_field_name
      "received_date"
    end

    def available_choices
      {}
    end
  end
end
