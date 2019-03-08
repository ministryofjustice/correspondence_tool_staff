#rubocop:disable Metrics/ClassLength
require './lib/translate_for_case'

class CasesController < ApplicationController
  include FOICasesParams
  include ICOCasesParams
  include SARCasesParams
  include OverturnedICOParams


  before_action :set_case,
                only: [
                  :approve,
                  :closure_outcomes,
                  :destroy_case_link,
                  :edit,
                  :edit_closure,
                  :execute_approve,
                  :extend_for_pit,
                  :extend_sar_deadline,
                  :execute_extend_for_pit,
                  :execute_extend_sar_deadline,
                  :execute_new_case_link,
                  :execute_upload_response_and_approve,
                  :execute_upload_response_and_return_for_redraft,
                  :execute_upload_responses,
                  :new_case_link,
                  :process_date_responded,
                  :record_late_team,
                  :remove_pit_extension,
                  :remove_sar_deadline_extension,
                  :response_upload_for_redraft,
                  :update_closure,
                  :upload_response_and_approve,
                  :upload_response_and_return_for_redraft,
                  :upload_responses,
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
                  :close,
                  :confirm_respond,
                  :confirm_destroy,
                  :destroy,
                  :execute_request_amends,
                  :flag_for_clearance,
                  :process_closure,
                  :process_respond_and_close,
                  :progress_for_clearance,
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
               .for_params(request.params)
               .scope
               .page(params[:page])
               .decorate
    @current_tab_name = 'all_cases'
    @can_add_case = policy(Case::Base).can_add_case?
  end

  def closed_cases
    unpaginated_cases =  @global_nav_manager
                           .current_page_or_tab
                           .cases
                           .includes(:outcome,
                                     :info_held_status,
                                     :assignments,
                                     :cases_exemptions,
                                     :exemptions)
                           .by_last_transitioned_date
    if download_csv_request?
      @cases = unpaginated_cases
    else
      @cases = unpaginated_cases.page(params[:page]).decorate
    end
    respond_to do |format|
      format.html     { render :closed_cases }
      format.csv do
        send_csv_cases('closed')
      end
    end
  end

  def incoming_cases
    @cases = @global_nav_manager
               .current_page_or_tab
               .cases
               .by_deadline
               .page(params[:page]).decorate
  end

  def my_open_cases
    unpaginated_cases = @global_nav_manager
                            .current_page_or_tab
                            .cases
                            .by_deadline
    if download_csv_request?
      @cases = unpaginated_cases
    else
      @cases = unpaginated_cases.page(params[:page]).decorate
    end
    @current_tab_name = 'my_cases'
    @can_add_case = policy(Case::Base).can_add_case?
    respond_to do |format|
      format.html     { render :index }
      format.csv do
        send_csv_cases('my-open')
      end
    end
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
      prepare_open_cases_collection(service)
    end

    @filter_crumbs = @query.filter_crumbs
    @current_tab_name = 'all_cases'
    @can_add_case = policy(Case::Base).can_add_case?
    respond_to do |format|
      format.html     { render :index }
      format.csv do
        send_csv_cases 'open'
      end
    end
  end

  def filter
    state_selector = StateSelector.new(params)
    redirect_url = make_redirect_url_with_additional_params(states: state_selector.states_for_url)
    redirect_to redirect_url
  end

  def new
    permitted_correspondence_types

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

  def create
    begin
      set_correspondence_type(params.fetch(:correspondence_type))
      service = CaseCreateService.new current_user, @correspondence_type_key, params
      authorize service.case_class, :can_add_case?
      service.call
      @case = service.case
      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = service.flash_notice
        redirect_to new_case_assignment_path @case
      else # including :error
        @case = @case.decorate
        @case_types = @correspondence_type.sub_classes.map(&:to_s)
        @s3_direct_post = s3_uploader_for @case, 'requests'
        render :new
      end
    rescue ActiveRecord::RecordNotUnique
      flash[:notice] = t('activerecord.errors.models.case.attributes.number.duplication')
      render :new
    end
  end


  # The new action for overturned ICO cases is a separate action because it is a bit different
  #
  # from the other case types:
  #
  #   - it takes parameter (the id of the ICO appeal from which it is to be created)
  #
  # We can consider merging it back in to the generalised new, and having logic there to work out what to do
  # and what page to show, but am leaving it for now.
  #
  def new_overturned_ico
    overturned_case_class = determine_overturned_ico_class(params[:id])
    authorize overturned_case_class
    service = NewOverturnedIcoCaseService.new(params[:id])
    service.call
    if service.error?
      @case = service.original_ico_appeal.decorate
      render :show, :status => :bad_request
    else
      @case = service.overturned_ico_case.decorate
      @original_ico_appeal = service.original_ico_appeal
      set_correspondence_type(overturned_case_class.type_abbreviation.downcase)
      render :new
    end
  end

  def show
    if flash.key?(:query_id)
      SearchQuery.find(flash[:query_id])&.update_for_click(params[:pos].to_i)
    end

    if policy(@case).can_accept_or_reject_responder_assignment?
      redirect_to edit_case_assignment_path @case, @case.responder_assignment.id
    else
      authorize @case

      @correspondence_type_key = @case.type_abbreviation.downcase
      get_flash_errors_for_case(@case)
      set_permitted_events
      @accepted_now = params[:accepted_now]
      @case.sync_transition_tracker_for_user(current_user)
      render :show
    end
  end

  def edit
    set_correspondence_type(@case.type_abbreviation.downcase)
    authorize @case

    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    @s3_direct_post = s3_uploader_for(@case, 'requests')
    @case = @case.decorate
    render :edit
  end

  def edit_closure
    authorize @case, :update_closure?
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @case = @case.decorate
    @team_collection = CaseTeamCollection.new(@case)
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

  def approve
    authorize @case

    @case = @case.decorate
  end

  def execute_approve
    authorize @case, :approve?

    case_approval_service = CaseApprovalService.new(
      user: current_user,
      kase: @case,
      bypass_params: BypassParamsManager.new(params)
    )
    case_approval_service.call

    if case_approval_service.result == :ok
      current_team = CurrentTeamAndUserService.new(@case).team
      if @case.ico?
        flash[:notice] = t('notices.case/ico.case_cleared')
      else
        flash[:notice] = t('notices.case_cleared', team: current_team.name,
                                                   status: I18n.t("state.#{@case.current_state}").downcase)
      end
      redirect_to case_path(@case)
    else
      flash.now[:alert] = case_approval_service.error_message
      @case = @case.decorate
      render :approve
    end
  end

  def upload_responses
    authorize @case

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @case = @case.decorate
  end

  def execute_upload_responses
    authorize @case, :upload_responses?

    rus = ResponseUploaderService.new(
      kase: @case,
      current_user: current_user,
      action: 'upload',
      uploaded_files: params[:uploaded_files],
      upload_comment: params[:upload_comment],
      is_compliant: false,
      bypass_further_approval: false,
      bypass_message: nil
    )
    rus.upload!

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')

    case rus.result
    when :blank
      flash.now[:alert] = t('alerts.response_upload_blank?')
      render :upload_responses
    when :error
      flash.now[:alert] = t('alerts.response_upload_error')
      render :upload_responses
    when :ok
      flash[:notice] = t('notices.response_uploaded')
      set_permitted_events
      redirect_to case_path @case
    end
  end

  def upload_response_and_approve
    authorize @case

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @approval_action = 'approve'
    @case = @case.decorate
  end

  def execute_upload_response_and_approve
    authorize @case, :upload_response_and_approve?

    service = ResponseUploaderService.new(
      kase: @case,
      current_user: current_user,
      action: 'upload-approve',
      uploaded_files: params[:uploaded_files],
      upload_comment: params[:upload_comment],
      is_compliant: true,
      bypass_message: params.dig(:bypass_approval, :bypass_message),
      bypass_further_approval: params.dig(:bypass_approval, :press_office_approval_required) == 'false'
    )
    service.upload!

    @case = @case.decorate
    case service.result
    when :blank
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      flash.now[:alert] = t('alerts.response_upload_blank?')
      render :upload_response_and_approve
    when :error
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      flash.now[:alert] = t('alerts.response_upload_error')
      render :upload_response_and_approve
    when :ok
      flash[:notice] = t('notices.response_uploaded')
      set_permitted_events
      redirect_to case_path @case
    end
  end

  def upload_response_and_return_for_redraft
    authorize @case

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @approval_action = 'approve'
    @case = @case.decorate
  end

  def execute_upload_response_and_return_for_redraft
    authorize @case, :upload_response_and_return_for_redraft?

    rus = ResponseUploaderService.new(
      kase: @case,
      current_user: current_user,
      action: 'upload-redraft',
      uploaded_files: params[:uploaded_files],
      upload_comment: params[:upload_comment],
      is_compliant: params[:draft_compliant] == 'yes',
      bypass_message: nil,
      bypass_further_approval: false
    )
    rus.upload!

    @case = @case.decorate
    case rus.result
    when :blank
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      flash.now[:alert] = t('alerts.response_upload_blank?')
      render :upload_response_and_return_for_redraft
    when :error
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      flash.now[:alert] = t('alerts.response_upload_error')
      render :upload_response_and_return_for_redraft
    when :ok
      flash[:notice] = t('notices.response_uploaded')
      set_permitted_events
      redirect_to case_path @case
    end
  end

  def response_upload_for_redraft
    authorize @case

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @approval_action = 'redraft'
    @case = @case.decorate
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
    # prepopulate date if it was entered by the KILO
    authorize @case, :can_close_case?
    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end
    set_permitted_events
  end

  def process_date_responded
    authorize @case, :can_close_case?
    @case = @case.decorate

    @case.prepare_for_respond
    if !@case.update process_date_responded_params(@correspondence_type_key)
      render :close
    else
      @team_collection = CaseTeamCollection.new(@case)
      @case.update(late_team_id: @case.responding_team.id)
      redirect_to closure_outcomes_case_path(@case)
    end
  end

  def closure_outcomes
    @case = @case.decorate
    authorize @case, :can_close_case?
    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end
    @team_collection = CaseTeamCollection.new(@case)
  end

  def process_closure
    authorize @case, :can_close_case?
    @case = @case.decorate
    close_params = process_closure_params(@case.type_abbreviation)
    service = CaseClosureService.new(@case, current_user, close_params)
    service.call
    if service.result == :ok
      set_permitted_events
      flash[:notice] = service.flash_message
      redirect_to case_path(@case)
    else
      set_permitted_events
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @team_collection = CaseTeamCollection.new(@case)
      render :closure_outcomes
    end
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
      if @permitted_events.include?(:update_closure)
        flash[:notice] = "#{@close_flash_message}. #{ get_edit_close_link }".html_safe
      else
        flash[:notice] = @close_flash_message
      end
      redirect_to case_path(@case)
    else
      set_permitted_events
      @team_collection = CaseTeamCollection.new(@case)
      render :closure_outcomes
    end
  end



  def update_closure
    authorize @case
    close_params = process_closure_params(@case.type_abbreviation)
    @case.prepare_for_close

    service = UpdateClosureService.new(@case, current_user, close_params)
    service.call
    if service.result == :ok
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
    set_correspondence_type(@case.type_abbreviation.downcase)
  end

  def confirm_respond
    authorize @case, :can_respond?
    params = respond_params(@correspondence_type_key)
    service = MarkResponseAsSentService.new(@case, current_user, params)
    service.call
    case service.result
    when :ok
      flash[:notice] = t('.success')
      redirect_to case_path(@case)
    when :late
      @team_collection = CaseTeamCollection.new(@case)
      render '/cases/ico/late_team'
    when :error
      set_correspondence_type(@case.type_abbreviation.downcase)
      render :respond
    else
      raise 'unexpected result from MarkResponseAsSentService'
    end
  end

  # this action is only used for ICO cases
  def record_late_team
    authorize @case, :can_respond?
    @case.prepare_for_recording_late_team
    params = record_late_team_params(@case.type_abbreviation)
    if @case.update(params)
      @case.respond(current_user)
      redirect_to case_path
    else
      @team_collection = CaseTeamCollection.new(@case)
      render '/cases/ico/late_team'
    end
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
    unpaginated_cases = service.result_set
    if download_csv_request?
      @cases = unpaginated_cases
    else
      @cases = unpaginated_cases.page(@page).decorate
    end
    @filter_crumbs = @query.filter_crumbs
    respond_to do |format|
      format.html     { render :search }
      format.csv do
        send_csv_cases 'search'
      end
    end
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

  def request_amends
    authorize @case, :execute_request_amends?
    @next_step_info = NextStepInfo.new(@case, 'request-amends', current_user)
  end

  def execute_request_amends
    authorize @case
    CaseRequestAmendsService.new(
        user: current_user,
        kase: @case,
        message: params[:case][:request_amends_comment],
        is_compliant: params[:case][:draft_compliant] == 'yes').call
    if @case.sar?
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

  def remove_pit_extension
    authorize @case, :remove_pit_extension?

    service = CaseRemovePITExtensionService.new current_user,
                                            @case
    result = service.call

    if result == :ok
      flash[:notice] = 'Public Interest Test extensions removed'
      redirect_to case_path(@case.id)
    else
      flash[:alert] = "Unable to remove Public Interest Test extensions"
      redirect_to case_path(@case.id)
    end
  end

  def extend_sar_deadline
    authorize @case

    @case = CaseExtendSARDeadlineDecorator.decorate @case
  end

  def execute_extend_sar_deadline
    authorize @case, :extend_sar_deadline?

    service = CaseExtendSARDeadlineService.new(
      user: current_user,
      kase: @case,
      extension_days: params[:case][:extension_period],
      reason: params[:case][:reason_for_extending]
    )
    service.call

    if service.result == :ok
      flash[:notice] = t('.success')
      redirect_to case_path(@case.id)
    elsif service.result == :validation_error
      @case = CaseExtendSARDeadlineDecorator.decorate @case
      @case.reason_for_extending = params[:case][:reason_for_extending]
      render :extend_sar_deadline
    else
      flash[:alert] = t('.error', case_number: @case.number)
      redirect_to case_path(@case.id)
    end
  end

  def remove_sar_deadline_extension
    authorize @case, :remove_sar_deadline_extension?

    service = CaseRemoveSARDeadlineExtensionService.new(
      current_user,
      @case
    )
    service.call

    if service.result == :ok
      flash[:notice] = t('.success')
      redirect_to case_path(@case.id)
    else
      flash[:alert] = t('.error')
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
                                                acting_team: @case.team_for_unassigned_user(current_user, :responder),
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
          response = render_to_string(
            partial: "cases/#{ @correspondence_type_key }/case_linking/linked_cases",
            locals: {
              linked_cases: @linked_cases.map(&:decorate),
              link_type: @link_type,
            }
          )

          render status: :ok, json: { content: response, link_type: @link_type }.to_json

        else
          render status: :bad_request,
                 json: { linked_case_error: @linked_case_error,
                         link_type: @link_type }.to_json
        end
      end
    end
  end

  private

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

  def determine_overturned_ico_class(original_appeal_id)
    original_appeal_case = Case::ICO::Base.find original_appeal_id
    case original_appeal_case.type
      when 'Case::ICO::FOI'
        Case::OverturnedICO::FOI
      when 'Case::ICO::SAR'
        Case::OverturnedICO::SAR
      else
        raise ArgumentError.new 'Invalid case type for original ICO appeal'
    end
  end

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

  def prepare_select_type
    authorize Case::Base, :can_add_case?
  end

  def prepare_new_case
    valid_type = validate_correspondence_type(params[:correspondence_type].upcase)
    if valid_type == :ok
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
    when 'FOI', 'OVERTURNED_FOI' then process_foi_closure_params
    when 'SAR', 'OVERTURNED_SAR' then process_sar_closure_params
    when 'ICO' then process_ico_closure_params
    else raise "Unknown case type '#{correspondence_type}'"
    end
  end

  def missing_info_to_tmm
    if params[:case_sar][:missing_info] == "yes"
      @case.missing_info = true
      CaseClosure::RefusalReason.sar_tmm.abbreviation
    elsif params[:case_sar][:missing_info] == "no"
      @case.missing_info = false
    end
  end

  def edit_params(correspondence_type)
    case correspondence_type
      when 'foi' then edit_foi_params
      when 'ico' then edit_ico_params
      when 'sar' then edit_sar_params
    end
  end

  def respond_params(correspondence_type)
    case correspondence_type
    when 'foi' then respond_foi_params
    when 'sar' then respond_sar_params
    when 'ico' then respond_ico_params
    when 'overturned_foi', 'overturned_sar' then respond_overturned_params
    else raise "Unknown case type '#{correspondence_type}'"
    end
  end

  def process_date_responded_params(correspondence_type)
    case correspondence_type
    when 'foi' then respond_foi_params
    when 'sar' then respond_sar_params
    when 'ico' then ico_close_date_responded_params
    when 'overturned_foi', 'overturned_sar' then respond_overturned_params
    else raise "Unknown case type '#{correspondence_type}'"
    end
  end

  def record_late_team_params(correspondence_type)
    if correspondence_type == 'ICO'
      record_late_team_ico_params
    else
      raise '#record_late_team_params only valid for ICO cases'
    end
  end

  def set_decorated_case
    set_case
    @case = @case.decorate
    @case_transitions = @case_transitions.decorate
  end

  def set_case
    @case = Case::Base.find(params[:id])
    @case_transitions = @case.transitions.case_history.order(id: :desc)
    @correspondence_type_key = @case.type_abbreviation.downcase
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

  # Catch exceptions as a result of a user not being authorised to perform an
  # action on a case. The default behaviour is to redirect them to '/' but here
  # we change that for certain actions where it makes sense (i.e. ones that
  # operate on a case) so that they redirect to the case show page (e.g.
  # approve, upload_responses).
  def user_not_authorized(exception)
    case exception.query
    when 'approve?',
         'can_add_attachment?',
         /^add_response_to_flagged_case/,
         'upload_responses?',
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
    types = current_user.managing_teams.first.correspondence_types.menu_visible.order(:name).to_a
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

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias t4c translate_for_case
end
#rubocop:enable Metrics/ClassLength
