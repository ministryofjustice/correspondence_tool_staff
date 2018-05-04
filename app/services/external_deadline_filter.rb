class ExternalDeadlineFilter

  def self.available_deadlines
    today = Date.today
    three_days = 3.business_days.from_now
    ten_days = 10.business_days.from_now
    {
      date_value_1: { day: today.strftime("%d"), month: today.strftime("%m"), year: today.strftime("%Y") }.to_json,
      date_value_2: { day: three_days.strftime("%d"), month: three_days.strftime("%m"), year: three_days.strftime("%Y") }.to_json,
      date_value_3: { day: ten_days.strftime("%d"), month: ten_days.strftime("%m"), year: ten_days.strftime("%Y") }.to_json
    }

  end

  def initialize(search_query, results)
    @search_query = search_query
    @results = results
  end

  def call
    if @search_query.external_deadline_from && @search_query.external_deadline_to
      deadline_is_within_period(@search_query.external_deadline_from,
                                @search_query.external_deadline_to)
    else
      @results
    end
  end

  private

  def deadline_is_within_period(from_date, to_date)
    @results.deadline_within(from_date, to_date)
  end
end
