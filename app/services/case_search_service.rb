class CaseSearchService

  attr_reader :current_user,
              :error_message,
              :filter_type,
              :result_set,
              :query,
              :query_hash,
              :parent_hash,
              :unpaginated_result_set

  def initialize(current_user, params, parent_hash = nil)
    @current_user = current_user
    @policy_scope = Pundit.policy_scope!(@current_user, Case::Base)
    @query = params[:query].strip
    @page = params[:page]
    @error = false
    @error_message = nil
    @result_set = []
    @unpaginated_result_set = []

    if parent_hash.nil?
      @query_type = :search
      @parent_hash = nil
    else
      @filter_type = params[:filter]
      @query_type = :filter
      @parent_hash = parent_hash
    end

    @query_hash = CaseSearchService.generate_query_hash(@current_user, @query_type, @filter_type, @query)
  end

  def self.generate_query_hash(user, query_type, filter_type, query, date = Date.today)
    Digest::SHA256.hexdigest("#{user.id}:#{date.to_date}:#{query_type}:#{filter_type}:#{query}")
  end


  def call
    if @query.blank?
      @error_message = 'Specify what you want to search for'
      @error = true
    else
      search_and_filter
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

  def search_and_filter
    @unpaginated_result_set = child? ? child_search : root_search
    SearchQuery.create_from_search_service(self)
  end

  def root_search
    @policy_scope.search(@query)
  end

  def child_search
    ancestor_search_queries = SearchQuery.by_query_hash_with_ancestors!(@parent_hash)
    ancestor_search_queries.each do |search_query|
      if search_query.search?
        @unpaginated_result_set = @policy_scope.search(search_query.search_query)
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


