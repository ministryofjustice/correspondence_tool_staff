module Cases
  class SearchesController < ApplicationController
    include SetupCase
    include SearchParams

    def show
      set_url
      @state_selector = StateSelector.new(params)

      service = CaseSearchService.new(
        user: current_user,
        query_type: :search,
        query_params: search_params
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
        format.html
        format.csv { send_csv_cases 'search' }
      end
    end
  end
end
