module CaseFilter
  class DateRespondedFilter < CaseDateRangeFilterBase

    def self.date_field_name
      'date_responded'
    end

    def available_choices
      nine_months_start = beginning_of_month(Time.current.to_date, 9)
      nine_months_end = end_of_month(Time.current.to_date, 9)
      two_years_start = beginning_of_month(Time.current.to_date, 24)
      two_years_end = end_of_month(Time.current.to_date, 24)
      {
        up_to_nine_month: {
          name: '9 months ago',
          from: { day: nine_months_start.strftime("%d"), month: nine_months_start.strftime("%m"), year: nine_months_start.strftime("%Y") }.to_json,
          to: { day: nine_months_end.strftime("%d"), month: nine_months_end.strftime("%m"), year: nine_months_end.strftime("%Y") }.to_json
        },
        up_to_two_year: {
          name: '2 years ago',
          from: { day: two_years_start.strftime("%d"), month: two_years_start.strftime("%m"), year: two_years_start.strftime("%Y") }.to_json,
          to: { day: two_years_end.strftime("%d"), month: two_years_end.strftime("%m"), year: two_years_end.strftime("%Y") }.to_json
        }
      }
    end

    private 

    def beginning_of_month(bench_date, num_month_ago)
      (bench_date - (num_month_ago + 1).months).at_beginning_of_month
    end

    def end_of_month(bench_date, num_month_ago)
      ((bench_date - num_month_ago.months).at_beginning_of_month)-1
    end

  end
end
