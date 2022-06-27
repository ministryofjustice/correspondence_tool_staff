module Cases
  class FiltersController < ApplicationController
    include SetupCase
    include SearchParams
    include AvailableCaseReports
    include RetentionSchedulePageOrdering

    before_action :set_url, only: [:open, :closed, :my_open, :retention]
    before_action :set_state_selector, only: [:open, :my_open]
    before_action :set_retention_schedule_order_flag, only: [:retention]
    before_action :set_cookie_order_flag, only: [:open, :my_open]
    after_action :reset_default_order_from_retention_schedule_order_flag, only: [:retention]
    before_action :set_non_current_tab_counts, only: [:my_open]

    def show
      if params[:state_selector].present?
        state_selector = StateSelector.new(params)
        redirect_url = make_redirect_url_with_additional_params(states: state_selector.states_for_url)
        redirect_to redirect_url
      else
        redirect_to root_my_open_filter_path
      end
    end

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
      service = call_search_service(unpaginated_cases)
      @query = service.query

      if service.error?
        flash.now[:alert] = service.error_message
      else
        if download_csv_request?
          @cases = service.result_set.by_last_transitioned_date
        else
          @cases = service.result_set.by_last_transitioned_date.page(params[:page]).decorate
        end
      end

      @current_tab_name = 'closed'
      @filter_crumbs = @query.filter_crumbs
      respond_to do |format|
        format.html { render :closed }
        format.csv { send_csv_cases 'closed' }
      end
    end

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

      service = call_search_service(unpaginated_cases, cookies[:search_result_order])
      @query = service.query

      if service.error?
        flash.now[:alert] = service.error_message
      else
        prepare_open_cases_collection(service)
      end

      @filter_crumbs = @query.filter_crumbs  
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

      service = call_search_service(full_list_of_cases, cookies[:search_result_order])
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

    def retention
      full_list_of_cases = @global_nav_manager
        .current_page_or_tab
        .cases

      service = call_search_service(full_list_of_cases, cookies[:search_result_order])
      @query = service.query

      if service.error?
        flash.now[:alert] = service.error_message
      else
        prepare_open_cases_collection(service)
      end

      @filter_crumbs = @query.filter_crumbs
      @current_tab_name = "retention_#{@global_nav_manager.current_page_or_tab.name}"

      respond_to do |format|
        format.html { render :retention }
      end
    end

    private

    def set_non_current_tab_counts
      @global_nav_manager.current_page.tabs.each do |tab| 
        tab.set_count(filtered_count_for_tab(tab.cases))
      end
    end

    def filtered_count_for_tab(tab_case_list)
      call_search_service(tab_case_list).result_set.count
    end

    def call_search_service(list_of_cases, order_choice = nil)
      query_list_params = search_params.merge(list_path: request.path)
      service = CaseSearchService.new(
        user: current_user,
        query_type: :list,
        query_params: query_list_params
      )
      service.call(list_of_cases, order: order_choice)
      service
    end

    def set_cookie_order_flag
      if params["order"].present?
        set_order_cookie(params["order"]) 
      end
    end

    def set_order_cookie(order)
      cookies[:search_result_order] = {
        value: order,
        secure: true 
      }
    end

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
        next if key.to_sym.in?(%i[utf8 authenticity_token state_selector states action commit action orig_action page])
        new_params[key] = params[key]
      end

      url_for(new_params)
    end

  end
end
