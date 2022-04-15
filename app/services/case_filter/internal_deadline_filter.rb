module CaseFilter
  class InternalDeadlineFilter < CaseDateRangeFilterBase

    def self.date_field_name
      'internal_deadline'
    end

    def available_choices
      {
        today: {
          name: 'Today',
          from: { day: Time.current.to_date.strftime("%d"), month: Time.current.to_date.strftime("%m"), year: Time.current.to_date.strftime("%Y") }.to_json,
          to: { day: Time.current.to_date.strftime("%d"), month: Time.current.to_date.strftime("%m"), year: Time.current.to_date.strftime("%Y") }.to_json,
        },
        three_days: {
          name: 'In the next 3 days',
          from: { day: Time.current.to_date.strftime("%d"), month: Time.current.to_date.strftime("%m"), year: Time.current.to_date.strftime("%Y") }.to_json,
          to: { day: 3.business_days.from_now.strftime("%d"), month: 3.business_days.from_now.strftime("%m"), year: 3.business_days.from_now.strftime("%Y") }.to_json,
        },
        ten_days: {
          name: 'In the next 10 days',
          from: { day: Time.current.to_date.strftime("%d"), month: Time.current.to_date.strftime("%m"), year: Time.current.to_date.strftime("%Y") }.to_json,
          to: { day: 10.business_days.from_now.strftime("%d"), month: 10.business_days.from_now.strftime("%m"), year: 10.business_days.from_now.strftime("%Y") }.to_json
        }
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { 
        | c_type | ['FOI', 'SAR', 'ICO','OVERTURNED_FOI', 'OVERTURNED_SAR'].include? c_type.abbreviation 
      }
    end

    def call
      if presented?
        deadline_is_within_period(@query.internal_deadline_from,
                                  @query.internal_deadline_to)
      else
        @results
      end
    end

    private

    def deadline_is_within_period(from_date, to_date)
      @records.internal_deadline_within(from_date, to_date)
    end
  end
end
