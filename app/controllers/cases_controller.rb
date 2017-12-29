#rubocop:disable Metrics/ClassLength

class CasesController < ApplicationController
  before_action :set_case,
                only: [
                  :extend_for_pit,
                  :execute_extend_for_pit,
                  :execute_new_case_link,
                  :new_case_link
                ]
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
                  :reassign_approver,
                  :remove_clearance,
                  :request_amends,
                  :request_further_clearance,
                  :respond,
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

    # TODO: This needs to be true for any type of case, really.
    @can_add_case = policy(Case::FOI::Standard).can_add_case?
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

    # TODO: This needs to be true for any type of case, really.
    @can_add_case = policy(Case::FOI::Standard).can_add_case?
    render :index
  end

  def open_cases
    @cases = @global_nav_manager
               .current_page_or_tab
               .cases
               .by_deadline
               .page(params[:page])
               .decorate

    # .by_deadline
    @current_tab_name = 'all_cases'
    # TODO: This needs to be true for any type of case, really.
    @can_add_case = policy(Case::FOI::Standard).can_add_case?
    render :index
  end

  def filter
    state_selector = StateSelector.new(params)
    redirect_url = make_redirect_url_with_additional_params(states: state_selector.states_for_url)
    redirect_to redirect_url
  end

  def select_type
    @case = Case::Base.new
  end

  def new
    case_class = params[:case].fetch(:type, 'Case::FOI::Standard').constantize
    # TODO: Should be authorizing :create?
    authorize case_class, :can_add_case?

    @case = case_class.new
    @s3_direct_post = s3_uploader_for(@case, 'requests')
    render :new
  end

  def create
    case_class = params[:case].fetch(:type, 'Case::FOI::Standard').constantize
    # TODO: Should be authorizing :create?
    authorize case_class, :can_add_case?

    service = CaseCreateService.new current_user, create_foi_params
    service.call
    @case = service.case
    case service.result
    when :case_created
      redirect_to case_path @case
    when :assign_responder
      flash[:creating_case] = true
      redirect_to new_case_assignment_path @case
    else # including :error
      @s3_direct_post = s3_uploader_for @case, 'requests'
      render :new
    end

  rescue ActiveRecord::RecordNotUnique
    flash[:notice] =
      t('activerecord.errors.models.case.attributes.number.duplication')
    render :new
  end

  def show
    if policy(@case).can_accept_or_reject_responder_assignment?
      redirect_to edit_case_assignment_path @case, @case.responder_assignment.id
    else
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
    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    authorize @case

    render :edit
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
      redirect_to cases_path
    end
  end

  def update
    @case = Case::Base.find(params[:id])
    authorize @case

    service = CaseUpdaterService.new(current_user, @case, create_foi_params)
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
      render :edit
    end
  end

  def close
    authorize @case, :can_close_case?
    @case.date_responded = nil
    set_permitted_events
  end

  def process_closure
    authorize @case, :can_close_case?
    @case.prepare_for_close
    if @case.update(process_closure_params)
      @case.close(current_user)
      set_permitted_events
      flash[:notice] = t('notices.case_closed')
      redirect_to case_path(@case)
    else
      set_permitted_events
      render :close
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
    @query = params[:query]
    @current_tab_name = 'search'
    if @query.present?
      @query.strip!
      @cases = policy_scope(Case::Base).search(@query).page(params[:page]).decorate
      if @cases.empty?
        flash.now[:alert] = 'No cases found'
      end
    else
      @cases = nil
    end
    render :index
  end

  def unflag_taken_on_case_for_clearance
    authorize @case, :can_unflag_for_clearance?
    service = CaseUnflagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: BusinessUnit.dacu_disclosure,
                                      message: params[:message])
    service.call
    if service.result == :ok
      flash[:notice] = "Clearance removed for case #{@case.number}"
      redirect_to cases_path
    end
  end

  def unflag_for_clearance
    authorize @case, :can_unflag_for_clearance?
    CaseUnflagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: BusinessUnit.dacu_disclosure,
                                      message: params[:message]).call
  end

  def flag_for_clearance
    authorize @case, :can_flag_for_clearance?
    CaseFlagForClearanceService.new(user: current_user,
                                    kase: @case,
                                    team: BusinessUnit.dacu_disclosure).call
  end

  def approve_response_interstitial
    authorize @case, :can_approve_or_escalate_case?
  end

  def request_amends
    authorize @case
    @next_step_info = NextStepInfo.new(@case, 'request-amends', current_user)
  end

  def execute_response_approval
    authorize @case

    bypass_params_manager = BypassParamsManager.new(params)
    service = CaseApprovalService.new(user: current_user, kase: @case, bypass_params: bypass_params_manager)
    service.call
    if service.result == :ok
      flash[:notice] = "You have cleared case #{@case.number} - #{@case.subject}."
      redirect_to cases_path
    else
      flash[:alert] = service.error_message
      render :approve_response_interstitial
    end
  end

  def execute_request_amends
    authorize @case
    @case.request_amends_comment = params[:case][:request_amends_comment]
    CaseRequestAmendsService.new(user: current_user, kase: @case).call
    flash[:notice] = "You have requested amends to case #{@case.number} - #{@case.subject}."
    redirect_to cases_path
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

    result = service.call


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

  private

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
    @permitted_events = @permitted_events - [:extend_for_pit, :request_further_clearance, :link_a_case]
  end

  def process_closure_params
    params.require(:case).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :outcome_name,
      :appeal_outcome_name,
      :refusal_reason_name,
      :info_held_status_abbreviation,
      exemption_ids: params[:case][:exemption_ids].nil? ? nil : params[:case][:exemption_ids].keys
    )
  end

  def create_foi_params
    params.require(:case).permit(
      :type,
      :requester_type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: [],
    )
  end

  def edit_params
    params.require(:case).permit(
      :category_id
    )
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
         'new_response_upload?'
      super(exception, case_path(@case))
    else
      super
    end
  end

  def get_flash_errors_for_case(kase)
    if flash.key?(:case_errors)
      flash[:case_errors]['message_text'].each do |error|
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
#rubocop:enable Metrics/ClassLength
