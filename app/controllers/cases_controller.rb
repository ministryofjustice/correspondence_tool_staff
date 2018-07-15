#rubocop:disable Metrics/ClassLength

class CasesController < ApplicationController
  include FOICasesParams
  include ICOCasesParams
  include SARCasesParams

  before_action :set_case,
                only: [
                  :edit_closure,
                  :extend_for_pit,
                  :execute_extend_for_pit,
                  :execute_new_case_link,
                  :new_case_link,
                  :destroy_case_link,
                  :update_closure
                ]
  before_action :set_url, only: [:search, :open_cases]

  # As per the Draper documentation, we really shouldn't be decorating @case at
  # the beginning of controller actions (see:
  # https://github.com/drapergem/draper#when-to-decorate-objects) as we do
  # here. Unfortunately we have a good bit of code that already relies on @case
  # being a decorator so instead of changing each of these actions let's
  # relegate them to a deprecated 'set_decorated_case' and change `set_case` to
  # not decorate @case. Also, as "case" is a reserved word in Ruby, the
  # suggestion in the Draper documentation isn't the best idea. So for an
  # action to move from using set_decorated_case to set_case it will have to
  # re-assign @case to be decorated, e.g.:
  #
  #   @case = @case.decorate
  #
  # or, this could be done in a new after_action block.
  before_action :set_decorated_case,
                only: [
                  :approve_response_interstitial,
                  :assign_to_new_team,
                  :close,
                  :confirm_respond,
                  :confirm_destroy,
                  :destroy,
                  :execute_response_approval,
                  :execute_request_amends,
                  :flag_for_clearance,
                  :new_response_upload,
                  :process_closure,
                  :process_respond_and_close,
                  :progress_for_clearance,
                  :reassign_approver,
                  :remove_clearance,
                  :request_amends,
                  :request_further_clearance,
                  :respond,
                  :respond_and_close,
                  :show,
                  :update,
                  :unflag_for_clearance,
                  :unflag_taken_on_case_for_clearance,
                  :upload_responses,
                ]
  before_action :set_assignments, only: [:show]
  before_action :set_state_selector, only: [:open_cases, :my_open_cases]

  def index
    @cases = CaseFinderService.new(current_user)
               .for_user
               .for_params(request.params)
               .scope
               .page(params[:page])
               .decorate
    @current_tab_name = 'all_cases'
    @can_add_case = policy(Case::Base).can_add_case?
  end

  def closed_cases
    @cases = @global_nav_manager
               .current_page_or_tab
               .cases
               .by_deadline
               .page(params[:page])
               .decorate
  end

  def incoming_cases
    @cases = @global_nav_manager
               .current_page_or_tab
               .cases
               .by_deadline
               .page(params[:page]).decorate
  end

  def my_open_cases
    @cases = @global_nav_manager
               .current_page_or_tab
               .cases
               .by_deadline
               .page(params[:page])
               .decorate
    @current_tab_name = 'my_cases'
    @can_add_case = policy(Case::Base).can_add_case?

    render :index
  end

  def open_cases
    full_list_of_cases = @global_nav_manager.current_page_or_tab.cases

    query_list_params = filter_params.merge(
      list_path: request.path,
    )
    service = CaseSearchService.new(user: current_user,
                                    query_type: :list,
                                    query_params: query_list_params)
    service.call(full_list_of_cases)
    @query = service.query
    if service.error?
      flash.now[:alert] = service.error_message
    else
      @page = params[:page] || '1'
      @cases = service.result_set.by_deadline.page(@page).decorate
      @parent_id = @query.id
      flash[:query_id] = @query.id
    end

    @filter_crumbs = @query.filter_crumbs
    @current_tab_name = 'all_cases'
    @can_add_case = policy(Case::Base).can_add_case?
    render :index
  end

  def filter
    state_selector = StateSelector.new(params)
    redirect_url = make_redirect_url_with_additional_params(states: state_selector.states_for_url)
    redirect_to redirect_url
  end

  def new
    permitted_correspondence_types
    @linked_case_errors = nil
    if FeatureSet.sars.disabled? && FeatureSet.ico.disabled?
      set_correspondence_type('foi')
      prepare_new_case
      render :new
    elsif params[:correspondence_type].present?
      set_correspondence_type(params[:correspondence_type])
      prepare_new_case
      render :new
    else
      # set_creatable_correspondence_types
      prepare_select_type
      render :select_type
    end
  end

  def create #rubocop:disable Metrics/MethodLength
    set_correspondence_type(params.fetch(:correspondence_type))
    @linked_case_errors = nil
    case_params = create_params(@correspondence_type_key)

    case_class_service = GetCaseClassFromParamsService.new(
      type: @correspondence_type,
      params: params["case_#{@correspondence_type_key}"]
    )
    case_class_service.call()
    if case_class_service.error?
      permitted_correspondence_types
      prepare_new_case
      @case.assign_attributes(case_params)
      case_class_service.set_error_on_case(@case)
      render(:new)
    else
      case_class = case_class_service.case_class
      authorize case_class, :can_add_case?

      service = CaseCreateService.new current_user, case_class, case_params
      service.call
      @case = service.case
      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = "#{@case.type_abbreviation} case created<br/>Case number: #{@case.number}".html_safe
        redirect_to new_case_assignment_path @case
      else # including :error
        @case_types = @correspondence_type.sub_classes.map(&:to_s)
        @s3_direct_post = s3_uploader_for @case, 'requests'
        render :new
      end
    end

  rescue ActiveRecord::RecordNotUnique
    flash[:notice] =
      t('activerecord.errors.models.case.attributes.number.duplication')
    render :new
  end

  def show
    if flash.key?(:query_id)
      SearchQuery.find(flash[:query_id])&.update_for_click(params[:pos].to_i)
    end

    if policy(@case).can_accept_or_reject_responder_assignment?
      redirect_to edit_case_assignment_path @case, @case.responder_assignment.id
    else
      authorize @case

      get_flash_errors_for_case(@case)
      set_permitted_events
      @accepted_now = params[:accepted_now]
      @case.sync_transition_tracker_for_user(current_user)
      render :show
    end
  end

  def edit
    # cannot use a decorated case here because the requester type radio buttons
    # do not populate if you do
    #
    @case = Case::Base.find(params[:id])
    set_correspondence_type(@case.type_abbreviation.downcase)
    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    authorize @case

    @case = @case.decorate
    render :edit
  end

  def edit_closure
    authorize @case, :update_closure?
    @case = @case.decorate
  end

  def confirm_destroy
    authorize @case
  end

  def destroy
    authorize @case
    service = CaseDeletionService.new(current_user, @case)
    service.call
    if service.result == :ok
      flash[:notice] = "You have deleted case #{@case.number}."
      redirect_to cases_path
    else
      render :confirm_destroy
    end
  end

  def new_response_upload
    flash[:action_params] = request.query_parameters['mode']
    authorize_upload_response_for_action @case, flash[:action_params]
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
  end

  def upload_responses
    authorize_upload_response_for_action @case, flash[:action_params]

    bypass_params_manager = BypassParamsManager.new(params)
    rus = ResponseUploaderService.new(
      @case, current_user, bypass_params_manager, flash[:action_params]
    )
    rus.upload!
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    case rus.result
    when :blank
      flash.now[:alert] = t('alerts.response_upload_blank?')
      flash.keep(:action_params)
      render :new_response_upload
    when :error
      flash.now[:alert] = t('alerts.response_upload_error')
      flash.keep(:action_params)
      render :new_response_upload
    when :ok
      flash[:notice] = t('notices.response_uploaded')
      set_permitted_events
      redirect_to case_path @case
    end
  end

  def update
    set_correspondence_type(params.fetch(:correspondence_type))
    @case = Case::Base.find(params[:id])
    authorize @case

    case_params = edit_params(@correspondence_type_key)
    service = CaseUpdaterService.new(current_user, @case, case_params)
    service.call
    if service.result != :error
      if service.result == :ok
        flash[:notice] = t('.case_updated')
      elsif service.result == :no_changes
        flash[:alert] = "No changes were made"
      end

      set_permitted_events
      @case = @case.decorate
      @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
      redirect_to case_path(@case)
    else
      @case = @case.decorate
      render :edit
    end
  end

  def close
    authorize @case, :can_close_case?
    @case.date_responded = nil
    set_permitted_events
  end

  def respond_and_close
    authorize @case
    @case.date_responded = nil
    set_permitted_events
    render :close
  end


  def process_respond_and_close
    authorize @case, :respond_and_close?
    @case.prepare_for_close
    close_params = process_closure_params(@case.type_abbreviation)
    if @case.update(close_params)
      @case.respond_and_close(current_user)
      set_permitted_events
      @close_flash_message = t('notices.case_closed')
      flash[:notice] = "#{@close_flash_message}. #{ get_edit_close_link }".html_safe
      redirect_to case_path(@case)
    else
      set_permitted_events
      render :close
    end
  end

  def process_closure
    authorize @case, :can_close_case?

    @case.prepare_for_close
    close_params = process_closure_params(@case.type_abbreviation)
    if @case.update(close_params)
      @case.close(current_user)
      set_permitted_events
      flash[:notice] = t('notices.case_closed')
      redirect_to case_path(@case)
    else
      set_permitted_events
      render :close
    end
  end

  def update_closure
    authorize @case

    @case.prepare_for_close
    close_params = process_closure_params(@case.type_abbreviation)
    if @case.update(close_params)
      @case.state_machine.update_closure!(acting_user: current_user,
                                          acting_team: @case.team_for_user(current_user))
      set_permitted_events
      flash[:notice] = t('notices.closure_details_updated')
      redirect_to case_path(@case)
    else
      @case = @case.decorate
      render :edit_closure
    end
  end

  def respond
    authorize @case, :can_respond?
  end

  def confirm_respond
    authorize @case, :can_respond?
    @case.respond(current_user)
    flash[:notice] = t('.success')
    redirect_to case_path(@case)
  end

  def search
    service = CaseSearchService.new(user: current_user,
                                    query_type: :search,
                                    query_params: filter_params)
    service.call
    @query = service.query
    if service.error?
      flash.now[:alert] = service.error_message
    else
      @page = params[:page] || '1'
      @parent_id = @query.id
      flash[:query_id] = @query.id
    end
    @cases = service.result_set.page(@page).decorate
    @filter_crumbs = @query.filter_crumbs
  end


  def remove_clearance
    authorize @case
    # interstitial page for unflag_taken_on_case_for_clearance
  end

  def unflag_taken_on_case_for_clearance
    authorize @case, :unflag_for_clearance?
    service = CaseUnflagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: BusinessUnit.dacu_disclosure,
                                      message: params[:message])
    service.call
    if service.result == :ok
      flash[:notice] = "Clearance removed for this case."
      redirect_to case_path(@case)
    end
  end

  def unflag_for_clearance
    authorize @case
    CaseUnflagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: BusinessUnit.dacu_disclosure,
                                      message: params[:message]).call

    respond_to do |format|
      format.js { render 'cases/unflag_for_clearance.js.erb' }
      format.html do
        flash[:notice] = "Case has been de-escalated. #{ get_de_escalated_undo_link }".html_safe
        if @case.type_abbreviation == 'SAR'
          redirect_to incoming_cases_path
        else
          redirect_to case_path(@case)
        end
      end
    end
  end

  def flag_for_clearance
    authorize @case, :can_flag_for_clearance?
    CaseFlagForClearanceService.new(user: current_user,
                                    kase: @case,
                                    team: BusinessUnit.dacu_disclosure).call
    respond_to do |format|
      format.js { render 'cases/flag_for_clearance.js.erb' }
      format.html do
        redirect_to case_path(@case)
      end
    end
  end

  def approve_response_interstitial
    authorize @case, :can_approve_or_escalate_case?
  end

  def request_amends
    authorize @case, :execute_request_amends?
    @next_step_info = NextStepInfo.new(@case, 'request-amends', current_user)
  end

  def execute_response_approval
    authorize @case

    bypass_params_manager = BypassParamsManager.new(params)
    service = CaseApprovalService.new(user: current_user, kase: @case, bypass_params: bypass_params_manager)
    service.call
    if service.result == :ok
      flash[:notice] = I18n.t('notices.case_cleared')
      redirect_to case_path(@case)
    else
      flash[:alert] = service.error_message
      render :approve_response_interstitial
    end
  end

  def execute_request_amends
    authorize @case
    CaseRequestAmendsService.new(user: current_user, kase: @case, message: params[:case][:request_amends_comment]).call
    if @case.type_abbreviation == 'SAR'
      flash[:notice] = 'Information Officer has been notified a redraft is needed.'
    else
      flash[:notice] = 'You have requested amends to this case\'s response.'
    end
    redirect_to case_path(@case)
  end

  def extend_for_pit
    authorize @case

    @case = CaseExtendForPITDecorator.decorate @case
  end

  def execute_extend_for_pit
    authorize @case, :extend_for_pit?

    pit_params = params[:case]
    extension_deadline = Date.new(
      pit_params[:extension_deadline_yyyy].to_i,
      pit_params[:extension_deadline_mm].to_i,
      pit_params[:extension_deadline_dd].to_i
    ) rescue nil
    service = CaseExtendForPITService.new current_user,
                                          @case,
                                          extension_deadline,
                                          pit_params[:reason_for_extending]
    result = service.call

    if result == :ok
      flash[:notice] = 'Case extended for Public Interest Test (PIT)'
      redirect_to case_path(@case.id)
    elsif result == :validation_error
      @case = CaseExtendForPITDecorator.decorate @case
      @case.extension_deadline_yyyy = pit_params[:extension_deadline_yyyy]
      @case.extension_deadline_mm = pit_params[:extension_deadline_mm]
      @case.extension_deadline_dd = pit_params[:extension_deadline_dd]
      @case.reason_for_extending = pit_params[:reason_for_extending]
      render :extend_for_pit
    else
      flash[:alert] = "Unable to perform PIT extension on case #{@case.number}"
      redirect_to case_path(@case.id)
    end
  end

  def request_further_clearance
    authorize @case
    service = RequestFurtherClearanceService.new(user: current_user, kase: @case)

    result = service.call

    if result == :ok
      flash[:notice] = 'Further clearance requested'
      redirect_to case_path(@case.id)
    else
      flash[:alert] = "Unable to request further clearance on case #{@case.number}"
      redirect_to case_path(@case.id)
    end
  end

  def new_case_link
    authorize @case

    @case = CaseLinkDecorator.decorate @case
  end

  def execute_new_case_link
    authorize @case, :new_case_link?

    link_case_number = params[:case][:linked_case_number]

    service = CaseLinkingService.new current_user, @case, link_case_number

    result = service.create


    if result == :ok
      flash[:notice] = "Case #{link_case_number} has been linked to this case"
      redirect_to case_path(@case)
    elsif result == :validation_error
      @case = CaseLinkDecorator.decorate @case
      @case.linked_case_number = link_case_number
      render :new_case_link
    else
      flash[:alert] = "Unable to create a link to case #{link_case_number}"
      redirect_to case_path(@case)
    end
  end

  def destroy_case_link
    authorize @case, :new_case_link?

    linked_case_number = params[:linked_case_number]

    service = CaseLinkingService.new current_user, @case, linked_case_number

    result = service.destroy

    if result == :ok
      flash[:notice] = "The link to case #{linked_case_number} has been removed."
      redirect_to case_path(@case)
    else
      flash[:alert] = "Unable to remove the link to case #{linked_case_number}"
      redirect_to case_path(@case)
    end
  end

  def progress_for_clearance
    authorize @case

    @case.state_machine.progress_for_clearance!(acting_user: current_user,
                                                acting_team: @case.team_for_user(current_user),
                                                target_team: @case.approver_assignments.first.team)

    flash[:notice] = t('notices.progress_for_clearance')
    redirect_to case_path(@case.id)
  end

  def new_linked_cases_for
    set_correspondence_type(params.fetch(:correspondence_type))
    @link_type = params[:link_type].strip

    respond_to do |format|
      format.js do
        if process_new_linked_cases_for_params
          @linked_cases.each { |kase| authorize kase, :show? }

          if @link_type == 'original'
            response = render_to_string partial: "cases/#{ @correspondence_type_key }/case_linking/linked_#{ @link_type }_case",
                                        locals: { original_case: @linked_cases.map(&:decorate)}
          else
            response = render_to_string partial: "cases/#{ @correspondence_type_key }/case_linking/linked_#{ @link_type }_cases",
                                        locals: { related_linked_cases: @linked_cases.map(&:decorate)}
          end

          render status: :ok, json: { content: response, link_type: @link_type }.to_json

        else
          render status: :bad_request, json: { linked_case_error: @linked_case_error,
                         link_type: @link_type }.to_json
        end
      end
    end
  end

  private

  def set_url
    @action_url = request.env['PATH_INFO']
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

  def search_and_filter(full_list_of_cases = nil)
    service = CaseSearchService.new(current_user,
                                    params.slice(:search_query, :page))
    service.call(full_list_of_cases)
    @query = service.query
    if service.error?
      flash.now[:alert] = service.error_message
    else
      kases = service.result_set
      @parent_id = @query.id
      flash[:query_id] = @query.id
      @page = params[:page] || '1'
    end
    kases
  end

  def prepare_select_type
    authorize Case::Base, :can_add_case?
  end

  def prepare_new_case
    validation_result = validate_correspondence_type(params[:correspondence_type].upcase)
    if validation_result == :ok
      set_correspondence_type(params[:correspondence_type])
      default_subclass = @correspondence_type.sub_classes.first

      # Check user's authorisation
      #
      # We don't know what kind of case type (FOI Standard, IR Timeliness, etc)
      # they want to create yet, but we need to authenticate them against some
      # kind of case class, so pick the first subclass available to them. This
      # could be improved by making case_subclasses a list of the case types
      # they are permitted to create, and when that list is empty rejecting
      # authorisation.
      authorize default_subclass, :can_add_case?

      @case = default_subclass.new.decorate
      @case_types = @correspondence_type.sub_classes.map(&:to_s)
      @s3_direct_post = s3_uploader_for(@case, 'requests')
    else
      flash.alert =
          helpers.t "cases.new.correspondence_type_errors.#{validation_result}",
                    type: @correspondence_type_key
      redirect_to new_case_path
    end
  end

  def validate_correspondence_type(ct_abbr)
    ct_exists    = ct_abbr.in?(CorrespondenceType.pluck(:abbreviation))
    ct_permitted = ct_abbr.in?(@permitted_correspondence_types.map(&:abbreviation))

    if ct_exists && ct_permitted
      :ok
    elsif !ct_exists
      :unknown
    else
      :not_authorised
    end
  end

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
    @filtered_permitted_events = @permitted_events - [:extend_for_pit, :request_further_clearance, :link_a_case, :remove_linked_case]
  end

  def process_closure_params(correspondence_type)
    case correspondence_type
    when 'FOI' then process_foi_closure_params
    when 'SAR' then process_sar_closure_params
    else raise 'Unknown case type'
    end
  end

  def missing_info_to_tmm
    if params[:case_sar][:missing_info] == "yes"
      @case.missing_info = true
      CaseClosure::RefusalReason.tmm.abbreviation
    elsif params[:case_sar][:missing_info] == "no"
      @case.missing_info = false
    end
  end

  def create_params(correspondence_type)
    # Call case-specific create params, which we should be defined in concerns files.
    case correspondence_type
      when 'foi' then create_foi_params
      when 'sar' then create_sar_params
      when 'ico' then create_ico_params
    end
  end

  def edit_params(correspondence_type)
    case correspondence_type
      when 'foi' then edit_foi_params
      when 'sar' then edit_sar_params
    end
  end

  def set_decorated_case
    @case = Case::Base.find(params[:id]).decorate
    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
  end

  def set_case
    @case = Case::Base.find(params[:id])
    @case_transitions = @case.transitions.case_history.order(id: :desc)
  end

  def set_assignments
    @assignments = []
    if @case.responding_team.in? current_user.responding_teams
      @assignments << @case.responder_assignment
    end

    if current_user.approving_team.in? @case.approving_teams
      @assignments << @case.assignments.for_team(current_user.approving_team.id).last
    end
  end

  def user_not_authorized(exception)
    case exception.query
    when 'can_add_attachment?',
         /^add_response_to_flagged_case/,
         'upload_responses?',
         'new_response_upload?',
         'update_closure?'
      super(exception, case_path(@case))
    else
      super
    end
  end

  def get_flash_errors_for_case(kase)
    if flash.key?(:case_errors)
      flash[:case_errors][:message_text].each do |error|
        kase.errors.add(:message_text, error)
      end
    end
  end

  def authorize_upload_response_for_action(kase, action)
    case action
    when nil, 'upload'    then authorize kase, 'upload_responses?'
    when 'upload-flagged' then authorize kase, 'upload_responses_for_flagged?'
    when 'upload-approve' then authorize kase, 'upload_responses_for_approve?'
    when 'upload-redraft' then authorize kase, 'upload_responses_for_redraft?'
    end
  end

  def s3_uploader_for(kase, upload_type)
    S3Uploader.s3_direct_post_for_case(kase, upload_type)
  end

  def set_correspondence_type(type)
    @correspondence_type = CorrespondenceType.find_by_abbreviation(type.upcase)
    @correspondence_type_key = type
  end

  def set_state_selector
    @state_selector = StateSelector.new(params)
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

  # This is how we should be building @permitted_correspondence_types, but it
  # is missing policies on CorrespondenceType
  # def permitted_correspondence_types
  #   @permitted_correspondence_types = current_user
  #                                       .permitted_correspondence_types
  #                                       .find_all do |type|
  #     Pundit.policy(current_user, type).can_add_case?
  #   end
  # end

  # See the commented-out method above, that should be our replacement. We just
  # assume that whatever managing team we're on will give us create
  # permissions, but that isn't strictly true, we should let the policy decide
  # that.
  def permitted_correspondence_types
    # Use the intermediary variable "types" to update
    # @permitted_correspondence_types so that it's changed as an atomic
    # operation ... we don't want to possibly allow SAR or ICO types to be
    # permitted at any point.
    types = current_user.managing_teams.first.correspondence_types.order(:name).to_a
    types.delete(CorrespondenceType.sar) unless FeatureSet.sars.enabled?
    types.delete(CorrespondenceType.ico) unless FeatureSet.ico.enabled?
    @permitted_correspondence_types = types
  end

  def get_de_escalated_undo_link
    unlink_path = flag_for_clearance_case_path(id: @case.id)
    view_context.link_to "Undo",
                         unlink_path,
                         { method: :patch, class: 'undo-de-escalate-link'}
  end

  def get_edit_close_link
    edit_close_link = edit_closure_case_path(@case)
    view_context.link_to "Edit case closure details",
                         edit_close_link,
                         { class: "undo-take-on-link" }
  end
end
#rubocop:enable Metrics/ClassLength
