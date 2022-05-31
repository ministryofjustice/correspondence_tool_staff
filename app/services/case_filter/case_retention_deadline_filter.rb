module CaseFilter
  class CaseRetentionDeadlineFilter < CaseDateRangeFilterBase
    def self.date_field_name
      'planned_destruction_date'
    end

    def available_choices
      {
        today: {
          name: 'Today', from: today, to: today,
        },
        one_month: {
          name: '1 month', from: months_ago(1), to: today,
        },
        two_months: {
          name: '2 months', from: months_ago(2), to: today,
        },
        three_months: {
          name: '3 months', from: months_ago(3), to: today,
        },
        four_months: {
          name: '4 months', from: months_ago(4), to: today,
        },
      }
    end

    private

    def today
      months_ago(0)
    end

    def months_ago(months)
      {
        day: months.months.ago.strftime("%d"),
        month: months.months.ago.strftime("%m"),
        year: months.months.ago.strftime("%Y")
      }.to_json
    end
  end
end
