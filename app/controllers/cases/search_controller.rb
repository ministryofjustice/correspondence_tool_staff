module Cases
  class SearchController < BaseController
    before_action :set_url, only: [:index]
    before_action :set_state_selector, only: [:index]

    def index
      service = CaseSearchService.new(
        user: current_user,
        query_type: :search,
        query_params: filter_params
      )
      service.call
      @query = service.query

      if service.error?
        flash.now[:alert] = service.error_message
      else
        @page = params[:page] || '1'
        @parent_id = @query.id
        flash[:query_id] = @query.id
      end

      unpaginated_cases = service.result_set

      if download_csv_request?
        @cases = unpaginated_cases
      else
        @cases = unpaginated_cases.page(@page).decorate
      end

      @filter_crumbs = @query.filter_crumbs

      respond_to do |format|
        format.html { render :search }
        format.csv { send_csv_cases 'search' }
      end
    end

    private

    def filter_params
      params.fetch(:search_query, {}).permit(
        :search_text,
      )
    end

    def set_state_selector
      @state_selector = StateSelector.new(params)
    end
  end
end
