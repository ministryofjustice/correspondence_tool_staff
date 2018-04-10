class CaseSearchService

  attr_reader :current_user,
              :error_message,
              :result_set,
              :query,
              :query_hash,
              :unpaginated_result_set

  def initialize(current_user, params)
    @current_user = current_user
    @query = params[:query]
    @page = params[:page]
    @error = false
    @error_message = nil
    @result_set = []
    @query_hash = Digest::SHA256.hexdigest("#{@current_user.id}:#{Date.today}:#{@query}")
  end


  def call
    if @query.blank?
      @error_message = 'Specify what you want to search for'
      @error = true
    else
      execute_search
    end
  end

  def error?
    @error
  end

  private

  def execute_search
    @query.strip!
    policy_scope = Pundit.policy_scope!(@current_user, Case::Base)
    @unpaginated_result_set = policy_scope.search(@query)
    @result_set = @unpaginated_result_set.page(@page).decorate
    SearchQuery.create_from_search_service(self)
  end
end
