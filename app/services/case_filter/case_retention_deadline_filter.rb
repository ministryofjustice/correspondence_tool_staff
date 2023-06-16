module CaseFilter
  class CaseRetentionDeadlineFilter < CaseDateRangeFilterBase
    def self.date_field_name
      "planned_destruction_date"
    end

    def available_choices
      {
        due: {
          from: json_date(far_in_the_past), to: json_date(months: 0)
        },
        one_month: {
          from: json_date(days: 1), to: json_date(months: 1)
        },
        two_months: {
          from: json_date(months: 1, days: 1), to: json_date(months: 2)
        },
        three_months: {
          from: json_date(months: 2, days: 1), to: json_date(months: 3)
        },
        four_months: {
          from: json_date(months: 3, days: 1), to: json_date(months: 4)
        },
      }
    end

  private

    def far_in_the_past
      Date.new(2000, 0o1, 0o1)
    end

    def json_date(args)
      date = args.is_a?(Hash) ? Date.today.advance(args) : args

      {
        day: date.strftime("%d"),
        month: date.strftime("%m"),
        year: date.strftime("%Y"),
      }.to_json
    end
  end
end
