module Cases
  class FilterController < BaseController
    before_action :set_url, only: [:open]
    before_action :set_state_selector, only: [:open, :my_open]

    def closed
      unpaginated_cases = @global_nav_manager
        .current_page_or_tab
        .cases
        .includes(
          :outcome,
          :info_held_status,
          :assignments,
          :cases_exemptions,
          :exemptions
        )
        .by_last_transitioned_date

      if download_csv_request?
        @cases = unpaginated_cases
      else
        @cases = unpaginated_cases.page(params[:page]).decorate
      end

      respond_to do |format|
        format.html { render :closed_cases }
        format.csv { send_csv_cases 'closed' }
      end
    end

    # Users only want to see cases deleted in the last 6 months
    def deleted
      cases = Case::Base.unscoped
        .soft_deleted
        .updated_since(6.months.ago)
        .by_last_transitioned_date

      @cases = Pundit.policy_scope(current_user, cases)

      respond_to do |format|
        format.csv { send_csv_cases 'deleted' }
      end
    end

    def incoming
      @cases = @global_nav_manager
        .current_page_or_tab
        .cases
        .by_deadline
        .page(params[:page])
        .decorate
    end

    def my_open
      unpaginated_cases = @global_nav_manager
        .current_page_or_tab
        .cases
        .includes(
          :message_transitions,
          :responder,
          :responding_team,
          :approver_assignments
        )
        .by_deadline

      if download_csv_request?
        @cases = unpaginated_cases
      else
        @cases = unpaginated_cases.page(params[:page]).decorate
      end

      @current_tab_name = 'my_cases'
      @can_add_case = policy(Case::Base).can_add_case?

      respond_to do |format|
        format.html { render :index }
        format.csv { send_csv_cases 'my-open' }
      end
    end

    def open
      full_list_of_cases = @global_nav_manager
        .current_page_or_tab
        .cases
        .includes(
          :message_transitions,
          :responder,
          :approver_assignments,
          :managing_team,
          :responding_team
        )

      query_list_params = filter_params.merge(list_path: request.path)

      service = CaseSearchService.new(
        user: current_user,
        query_type: :list,
        query_params: query_list_params
      )
      service.call(full_list_of_cases)
      @query = service.query

      if service.error?
        flash.now[:alert] = service.error_message
      else
        prepare_open_cases_collection(service)
      end

      @filter_crumbs = @query.filter_crumbs
      @current_tab_name = 'all_cases'
      @can_add_case = policy(Case::Base).can_add_case?

      respond_to do |format|
        format.html { render :index }
        format.csv { send_csv_cases 'open' }
      end
    end

    # Formerly 'filter', now 'index'
    def filter
      state_selector = StateSelector.new(params)
      redirect_url = make_redirect_url_with_additional_params(states: state_selector.states_for_url)
      redirect_to redirect_url
    end


    private

    def set_state_selector
      @state_selector = StateSelector.new(params)
    end

    def prepare_open_cases_collection(service)
      @parent_id = @query.id
      @page = params[:page] || '1'
      @cases = service.result_set.by_deadline.decorate
      if download_csv_request?
        @cases = service.result_set.by_deadline
      else
        @cases = service.result_set.by_deadline.page(@page).decorate
      end
      flash[:query_id] = @query.id
    end

    def make_redirect_url_with_additional_params(new_params)
      new_params[:controller] = params[:controller]
      new_params[:action] = params[:orig_action]
      params.keys.each do |key|
        next if key.to_sym.in?( %i{ utf8 authenticity_token state_selector states action commit action orig_action page} )
        new_params[key] = params[key]
      end
      url_for(new_params)
    end

    def filter_params
      params.fetch(:search_query, {}).permit(
        :search_text,
        :parent_id,
        :external_deadline_from,
        :external_deadline_from_dd,
        :external_deadline_from_mm,
        :external_deadline_from_yyyy,
        :external_deadline_to,
        :external_deadline_to_dd,
        :external_deadline_to_mm,
        :external_deadline_to_yyyy,
        common_exemption_ids: [],
        exemption_ids: [],
        filter_assigned_to_ids: [],
        filter_case_type: [],
        filter_open_case_status: [],
        filter_sensitivity: [],
        filter_status: [],
        filter_timeliness: [],
      )
    end
  end
end
