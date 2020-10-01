module CaseFilter
  class DateRespondedFilter < CaseDateRangeFilterBase

    def self.date_field_name
      'date_responded'
    end

    def available_choices
      {}

    end

  end
end
