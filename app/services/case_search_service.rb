class CaseSearchService

  attr_reader :error_message, :result_set, :uuid, :query

  def initialize(current_user, params)
    @current_user = current_user
    @query = params[:query]
    @page = params[:page]
    @error = false
    @error_message = nil
    @result_set = []
    @uuid = SecureRandom.uuid
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
    @result_set = policy_scope.search(@query).page(@page).decorate
    SearchQuery.create_from_search_service(self)
    if @result_set.empty?
      @error = true
      @error_message = 'No cases found'
    end
  end
end
