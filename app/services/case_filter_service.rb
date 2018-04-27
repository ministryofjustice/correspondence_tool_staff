class CaseFilterService

  def initialize(arel, search_query)
    @arel = arel
    @filter_type = search_query.filter_type
    @query = search_query
  end

  def call
    filter_module = "#{@query['filter_type'].camelize}Filter".constantize
    filter_module.call(@query, @arel)
  end
end

