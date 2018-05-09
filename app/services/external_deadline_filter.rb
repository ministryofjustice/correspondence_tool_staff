class ExternalDeadlineFilter

  def self.available_deadlines
    {
      today: { day: Date.today.strftime("%d"), month: Date.today.strftime("%m"), year: Date.today.strftime("%Y") }.to_json,
      three_days: { day: 3.business_days.from_now.strftime("%d"), month: 3.business_days.from_now.strftime("%m"), year: 3.business_days.from_now.strftime("%Y") }.to_json,
      ten_days: { day: 10.business_days.from_now.strftime("%d"), month: 10.business_days.from_now.strftime("%m"), year: 10.business_days.from_now.strftime("%Y") }.to_json
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
