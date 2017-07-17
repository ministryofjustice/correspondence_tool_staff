#rubocop:disable Metrics/ClassLength
class CasesController < ApplicationController
  before_action :set_case,
    only: [
      :approve_response,
      :close,
      :confirm_respond,
      :edit,
      :execute_response_approval,
      :execute_request_amends,
      :flag_for_clearance,
      :new_response_upload,
      :process_closure,
      :reassign_approver,
      :request_amends,
      :respond,
      :show,
      :unflag_for_clearance,
      :update,
      :upload_responses,
    ]
  before_action :set_assignment, only: [:show]

  def index
    # index doesn't have a nav page defined so cannot use the GlobalNavManager
    # to provide it with a finder
    @cases = CaseFinderService.new.for_user(current_user)
                .for_action(:index)
                .filter_for_params(params)
                .cases
                .page(params[:page])
                .decorate
  end


  def closed_cases
    finder = @global_nav_manager.current_cases_finder
    @cases = finder.cases.page(params[:page]).decorate
  end

  def incoming_cases
    finder = @global_nav_manager.current_cases_finder
    @cases = finder.cases.page(params[:page]).decorate
  end

  def my_open_cases
    finder = @global_nav_manager.current_cases_finder
    @cases = finder.cases.page(params[:page]).decorate
    render :index
  end

  def open_cases
    finder = @global_nav_manager.current_cases_finder
    @cases = finder.cases.page(params[:page]).decorate
    render :index
  end

  def new
    authorize Case, :can_add_case?

    @case = Case.new
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
    render :new
  end

  def create
    authorize Case, :can_add_case?

    @case = Case.new(create_foi_params.merge(uploading_user: current_user))
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')

    if create_foi_params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      render :new
    elsif @case.save
      if create_foi_params[:flag_for_disclosure_specialists] == 'yes'
        CaseFlagForClearanceService.new(user: current_user,
                                        kase: @case,
                                        team: Team.dacu_disclosure).call
      end
      flash[:creating_case] = true
      redirect_to new_case_assignment_path @case
    else
      render :new
    end
  rescue ActiveRecord::RecordNotUnique
    flash[:notice] =
      t('activerecord.errors.models.case.attributes.number.duplication')
    render :new
  end

  def show
    authorize @case, :can_view_case_details?

    if policy(@case).can_accept_or_reject_responder_assignment?
      redirect_to edit_case_assignment_path @case, @case.responder_assignment.id
    else
      get_flash_errors_for_case(@case)
      set_permitted_events
      @accepted_now = params[:accepted_now]
      render :show
    end
  end

  def edit
    render :edit
  end

  def new_response_upload
    authorize @case

    @next_step_info = NextStepInfo.new(@case,
                                       request.query_parameters['action'],
                                       current_user)

    flash[:action_params] = request.query_parameters['action']
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
  end

  def upload_responses
    authorize @case

    @next_step_info = NextStepInfo.new(@case,
                                       flash[:action_params],
                                       current_user)
    rus = ResponseUploaderService.new(
      @case, current_user, params, flash[:action_params]
    )
    rus.upload!
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    case rus.result
    when :blank
      flash.now[:alert] = t('alerts.response_upload_blank?')
      render :new_response_upload
    when :error
      flash.now[:alert] = t('alerts.response_upload_error')
      flash.keep(:action_params)
      render :new_response_upload
    when :ok
      flash[:notice] = t('notices.response_uploaded')
      set_permitted_events
      redirect_to case_path
    end
  end

  def update
    if @case.update(parsed_edit_params)
      flash.now[:notice] = t('.case_updated')
      render :show
    else
      render :edit
    end
  end

  def close
    authorize @case, :can_close_case?
    set_permitted_events
  end

  def process_closure
    authorize @case, :can_close_case?
    @case.prepare_for_close
    if @case.update(process_closure_params)
      @case.close(current_user)
      set_permitted_events
      flash[:notice] = t('notices.case_closed')
      render :show
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
    redirect_to cases_path
  end

  def search
    @case = Case.search(params[:search])
    render :index
  end

  def unflag_for_clearance
    authorize @case, :can_unflag_for_clearance?
    CaseUnflagForClearanceService.new(user: current_user,
                                      kase: @case,
                                      team: Team.dacu_disclosure).call
  end

  def flag_for_clearance
    authorize @case, :can_flag_for_clearance?
    CaseFlagForClearanceService.new(user: current_user,
                                    kase: @case,
                                    team: Team.dacu_disclosure).call
  end

  def approve_response
    authorize @case, :can_approve_or_escalate_case?
    @next_step_info = NextStepInfo.new(@case, 'approve', current_user)
    render :approve_response
  end

  def request_amends
    authorize @case
    @next_step_info = NextStepInfo.new(@case, 'request-amends', current_user)
  end

  def execute_response_approval
    authorize @case
    CaseApprovalService.new(user: current_user, kase: @case).call
    flash[:notice] = "You have cleared case #{@case.number} - #{@case.subject}."
    redirect_to cases_path
  end

  def execute_request_amends
    authorize @case
    CaseRequestAmendsService.new(user: current_user, kase: @case).call
    flash[:notice] = "You have requested amends to case #{@case.number} - #{@case.subject}."
    redirect_to cases_path
  end

  private

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
  end

  def process_closure_params
    params.require(:case).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :outcome_name,
      :refusal_reason_name,
      exemption_ids: params[:case][:exemption_ids].nil? ? nil : params[:case][:exemption_ids].keys
    )
  end

  def create_foi_params
    params.require(:case).permit(
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
    ).merge(category_id: Category.find_by(abbreviation: 'FOI').id)
  end

  def parsed_edit_params
    edit_params.delete_if { |_key, value| value == "" }
  end

  def edit_params
    params.require(:case).permit(
      :category_id
    )
  end

  def set_case
    @case = Case.find(params[:id]).decorate
    @case_transitions = @case.transitions.order(id: :desc).decorate
  end

  def set_assignment
    if current_user.responder?
      @assignment = @case.assignments.for_team(current_user.responding_teams.first.id).last
    elsif current_user.approver?
      @assignment = @case.assignments.for_team(current_user.approving_team.id).last
    end
  end

  def user_not_authorized(exception)
    case exception.query
    when 'can_add_attachment?',
         'can_add_attachment_to_flagged_case?',
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
end
#rubocop:enable Metrics/ClassLength
