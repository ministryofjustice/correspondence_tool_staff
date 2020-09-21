module CaseFilter
  class ReceivedDateFilter < CaseDateRangeFilterBase

    def self.date_field_name
      'received_date'
    end

    def available_choices
      {
        up_to_nine_month: {
          name: 'Up to Nine month',
          from: { day: 9.months.ago.strftime("%d"), month: 9.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
          to: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json
        },
        nine_to_two_year: {
          name: 'Nine month to 2 year',
          from: { day: 24.months.ago.strftime("%d"), month: 24.months.ago.strftime("%m"), year: 24.months.ago.strftime("%Y") }.to_json,
          to: { day: 9.months.ago.strftime("%d"), month: 9.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
        },
        two_to_eight_year: {
          name: '2 to 8 year',
          from: { day: 96.months.ago.strftime("%d"), month: 96.months.ago.strftime("%m"), year: 96.months.ago.strftime("%Y") }.to_json,
          to: { day: 24.months.ago.strftime("%d"), month: 24.months.ago.strftime("%m"), year: 9.months.ago.strftime("%Y") }.to_json,
        }
      }

    end

  end
end
