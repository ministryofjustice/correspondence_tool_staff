class CaseSearchService
  attr_reader :current_user,
              :error_message,
              :filter_type,
              :result_set,
              :parent,
              :query,
              :query_params,
              :search_query

  def initialize(user:, query_type:, query_params:)
    begin
      @query_params = process_params(query_params)
      @current_user = user
      @query_type = query_type
      @error = false
      @error_message = nil
      @result_set = Case::Base.none
      setup_search_query
    rescue ArgumentError
      @error = true
      @error_message = 'Invalid date'
      @query = SearchQuery.new
    end
  end

  def call(full_list_of_cases = nil)
    if @error == false && @query.valid?
      @result_set = @query.results(full_list_of_cases)
      @query.update num_results: @result_set.size
    else
      @result_set = Case::Base.none
    end
    @result_set
  end

  def error?
    @error
  end

  private

  def setup_search_query
    if query_params.blank?
      @query = SearchQuery.new
    else
      @query = SearchQuery.find_or_create(@query_params.merge(
          user_id: @current_user.id,
          query_type: @query_type,
          ))
      @parent = @query.parent

      unless @query.valid?
        @error = true
        if @query.search_text.blank?
          @error_message = 'Specify what you want to search for'
        end
      end
    end
  end

  # Process the params in <tt>@query_params</tt> so that they're suitable for
  # use by the SeachQuery model.
  #
  # We delegate to existing filter classes to figure out what processing is
  # required for it's params so that we don't have to have complicated logic
  # here that tries to guess what needs to be done for incoming params.
  def process_params(params)
    params[:search_text]&.strip!

    SearchQuery::FILTER_CLASSES.each do |filter_class|
      filter_class.process_params!(params)
    end
    params
  end

end
