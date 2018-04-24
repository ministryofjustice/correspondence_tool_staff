class CaseSearchService

  attr_reader :current_user,
              :error_message,
              :filter_type,
              :result_set,
              :parent_hash,
              :query,
              :query_params,
              :query_hash,
              :search_query,
              :unpaginated_result_set

  def initialize(current_user, params, parent_hash = nil)
    @current_user = current_user
    @policy_scope = Pundit.policy_scope!(@current_user, Case::Base)
    @params = params.permit!
    @page = params[:page]
    @error = false
    @error_message = nil
    @result_set = []
    @unpaginated_result_set = []

    if parent_hash.nil?
      @query_type = :search
      @parent_hash = nil
      @parent = nil
    else
      @filter_type = params[:filter]
      @query_type = :filter
      @parent_hash = parent_hash
      @parent = SearchQuery.by_query_hash!(@parent_hash)
    end

    @query_hash = CaseSearchService.generate_query_hash(@current_user,
                                                        @query_type,
                                                        @filter_type,
                                                        @query_params)
    @query_params = params.require(:search_query)
    @query_params.permit!
    @query_params.extract!(:num_results,
                           :num_clicks,
                           :highest_position,
                           :created_at,
                           :update_at)
  end

  def self.generate_query_hash(user, query_type, filter_type, query_params, date = Date.today)
    Digest::SHA256.hexdigest(
      "#{user.id}:#{date.to_date}:#{query_type}:#{filter_type}:#{query_params.to_json}"
    )
  end


  def call

    if @query_type == :search && @query_params['search_text'].blank?
      @error_message = 'Specify what you want to search for'
      @error = true
    else
      @query = SearchQuery.find_by(query_hash: @query_hash)
      if @query.present?
        @unpaginated_result_set = @query.results
      else
        @query = SearchQuery.new(
          @query_params.merge(
            query_type: @query_type,
            user_id: current_user.id,
            parent_id: @parent&.id,
            query_hash: @query_hash,
            num_clicks: 0
          )
        )
        @unpaginated_result_set = @query.results
        @query.num_results = @unpaginated_result_set.count
        @query.save!
      end

      @result_set = @unpaginated_result_set.page(@page).decorate
    end
  end

  def filter?
   @query_type == :filter
  end

  def search?
    @query_type == :search
  end

  def child?
    @parent_hash.present?
  end

  def error?
    @error
  end

  private

  def find_or_create_search_query
  end

  # def search_and_filter
  #   # @unpaginated_result_set = child? ? child_search : root_search
  #   @unpaginated_result_set = @query.results
  # end

  def root_search
    @policy_scope.search(@query[:search_text])
  end

  def child_search
    ancestor_search_queries = SearchQuery.by_query_hash_with_ancestors!(@parent_hash)
    ancestor_search_queries.each do |search_query|
      if search_query.search?
        @unpaginated_result_set = @policy_scope.search(search_query.query['search_text'])
      else
        @unpaginated_result_set = CaseFilterService.new(@unpaginated_result_set, search_query).call
      end
    end
    #
    # now we've got the result set that we had before the this filter was applied,
    # so all we have to do now is to apply the filter and store search_query_record
    # in the database
    #
    new_search_query = SearchQuery.new_from_search_service(self)
    @unpaginated_result_set = CaseFilterService.new(@unpaginated_result_set, new_search_query).call
    new_search_query.num_results = @unpaginated_result_set.size
    new_search_query.save!
    @unpaginated_result_set
  end
end


