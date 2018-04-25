class CaseSearchService
  FILTER_ATTRIBUTES = [
    :filter_case_type,
    :filter_sensitivity,
    :filter_status,
    :exemption_ids,
    :common_exemption_ids,
    :filter_assigned_to_ids
  ]
  QUERY_ATTRIBUTES = [:search_text] + FILTER_ATTRIBUTES

  attr_reader :current_user,
              :error_message,
              :filter_type,
              :result_set,
              :parent,
              :query,
              :query_params,
              :search_query,
              :unpaginated_result_set

  def initialize(current_user, params)
    @current_user = current_user
    @params = params.permit!
    @page = params[:page]
    @error = false
    @error_message = nil
    @result_set = []
    @unpaginated_result_set = []

    @query_params = params.require(:search_query)
    @query_params.permit!
    @query_params.extract!(:num_results,
                           :num_clicks,
                           :highest_position,
                           :created_at,
                           :update_at)
    @query_params = remove_blank_filter_values(@query_params)

    if @query_params[:parent_id]
      @parent = SearchQuery.find(@query_params[:parent_id])
      @query_type = :filter
    else
      @parent = nil
      @query_type = :search
      @query_params[:search_text].strip!
    end

    @query = find_or_initialize_query(@query_params,
                                      query_type: @query_type,
                                      user_id: current_user.id)
  end

  def call
    if @query_type == :search && @query_params['search_text'].blank?
      @error_message = 'Specify what you want to search for'
      @error = true
    else
      @unpaginated_result_set = @query.results
      @query.num_results = @unpaginated_result_set.size
      @query.save!
      @result_set = @unpaginated_result_set.page(@page).decorate
    end
  end

  def error?
    @error
  end

  private

  def remove_blank_filter_values(query_params)
    stripped_filter_values = query_params
                               .slice(*FILTER_ATTRIBUTES)
                               .transform_values { |values| values.grep_v '' }
                               .transform_values { |value| value.is_a?(Array) ? value.sort : value }
    query_params.merge(stripped_filter_values)
  end

  def find_or_initialize_query(query_params, query_type:, user_id:)
    if query_params.key? :parent_id
      @parent = SearchQuery.find(query_params[:parent_id])
      parent_query_params = @parent.slice(*QUERY_ATTRIBUTES)
      query_params = parent_query_params.merge(query_params.to_unsafe_h)
    end

    params_to_match_on = query_params.slice(*QUERY_ATTRIBUTES).to_h
    search_query = SearchQuery
                     .where(user_id: user_id)
                     .where('created_at >= ? AND created_at < ?',
                            Date.today, Date.tomorrow)
                     .where('query = ?', params_to_match_on.to_json)
                     .first
    if search_query.nil?
      search_query = SearchQuery.new(
        query_params.merge(
          query_type: query_type,
          user_id: user_id,
        )
      )
    end
    search_query
  end
end

