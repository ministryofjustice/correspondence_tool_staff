module CaseFilter
  class ExternalDeadlineFilter < CaseDateRangeFilterBase
    def self.date_field_name
      "external_deadline"
    end

    def available_choices
      {
        today: {
          name: "Today",
          from: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
          to: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
        },
        three_days: {
          name: "In the next 3 days",
          from: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
          to: { day: 3.business_days.from_now.strftime("%d"), month: 3.business_days.from_now.strftime("%m"), year: 3.business_days.from_now.strftime("%Y") }.to_json,
        },
        ten_days: {
          name: "In the next 10 days",
          from: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
          to: { day: 10.business_days.from_now.strftime("%d"), month: 10.business_days.from_now.strftime("%m"), year: 10.business_days.from_now.strftime("%Y") }.to_json,
        },
      }
    end

    def call
      if presented?
        deadline_is_within_period(@query.external_deadline_from,
                                  @query.external_deadline_to)
      else
        @results
      end
    end

  private

    def deadline_is_within_period(from_date, to_date)
      @records.deadline_within(from_date, to_date)
    end
  end
end
