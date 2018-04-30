class ExternalDeadlineFilter

  def initialize(search_query, results)
    @results = results
    @search_query = search_query
                            # external_deadline_from_dd
                            # external_deadline_from_mm
                            # external_deadline_from_yyyy
                            # external_deadline_to_dd
                            # external_deadline_to_mm
                            # external_deadline_to_yyyy
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
    @results.where("properties->>'external_deadline' BETWEEN ? AND ?", from_date, to_date)
  end
end
