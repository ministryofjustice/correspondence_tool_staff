class ExternalDeadlineFilter

  def self.available_deadlines
    {
      today:  Date.today,
      three_days: 3.business_days.from_now,
      ten_days: 10.business_days.from_now
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
