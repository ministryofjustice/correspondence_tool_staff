module Cases
  class FiltersController < ApplicationController
    include SetupCase
    include SearchParams

    before_action :set_url, only: [:open]
    before_action :set_state_selector, only: [:open, :my_open]
    before_action :set_search_query, only: [:closed, :my_open]

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
        .by_last_transitioned_date

      if download_csv_request?
        @cases = unpaginated_cases
      else
        @cases = unpaginated_cases.page(params[:page]).decorate
      end

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

      call_search_service(full_list_of_cases)

      @filter_crumbs = @query.filter_crumbs
      @current_tab_name = 'all_cases'
      @can_add_case = policy(Case::Base).can_add_case?
      @reports_for_open_cases = get_reports_for_open_cases
      respond_to do |format|
        format.html { render :index }
        format.csv { send_csv_cases 'open' }
      end
    end

    # @note (mseedat-moj): Was cases#index but is not currently used
    # def index
    #   @cases = CaseFinderService.new(current_user)
    #     .for_params(request.params)
    #     .scope
    #     .page(params[:page])
    #     .decorate
    #
    #   @state_selector = StateSelector.new(params)
    #   @current_tab_name = 'all_cases'
    #   @can_add_case = policy(Case::Base).can_add_case?
    # end


    private

    def call_search_service(full_list_of_cases)
      query_list_params = search_params.merge(list_path: request.path)
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
    end

    def set_search_query
      service = CaseSearchService.new(
        user: current_user,
        query_type: :search,
        query_params: search_params
      )
      service.call
      @query = service.query
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


    def include_offender_sar
      current_user.permitted_correspondence_types.include?(CorrespondenceType.offender_sar)
    end 

    def include_foi
      current_user.permitted_correspondence_types.include?(CorrespondenceType.foi) ||
      current_user.permitted_correspondence_types.include?(CorrespondenceType.overturned_foi)
    end 

    def include_sar
      current_user.permitted_correspondence_types.include?(CorrespondenceType.sar) ||
      current_user.permitted_correspondence_types.include?(CorrespondenceType.overturned_sar)
    end 

    def is_report_allowed(report_type)
      result = report_type.offender_sar && include_offender_sar
      if !result
        result = report_type.foi && include_foi
      end
      if !result
        result = report_type.sar && include_sar
      end
      result
    end

    def is_not_open_case_report(report_type)
      report_type.abbr.match(/^R30/).nil?
    end

    def get_reports_for_open_cases
      reports = []
      ReportType.all.each do |report_type|
        if is_not_open_case_report(report_type)
          next
        end 
        if is_report_allowed(report_type)
          reports << report_type
        end 
      end
      reports
    end
  end
end
