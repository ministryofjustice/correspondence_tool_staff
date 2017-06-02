class CasesController < ApplicationController
  before_action :set_case,
    only: [
      :approve_response,
      :close,
      :confirm_respond,
      :edit,
      :execute_response_approval,
      :flag_for_clearance,
      :new_response_upload,
      :process_closure,
      :reassign_approver,
      :respond,
      :show,
      :unflag_for_clearance,
      :update,
      :upload_responses,
    ]
  before_action :set_s3_direct_post, only: [:new_response_upload, :upload_responses]

  def index
    # index doesn't have a nav page defined so cannot use the GlobalNavManager
    # to provide it with a finder
    @cases = CaseFinderService.new.for_user(current_user)
               .for_action(:index)
               .filter_for_params(params)
  end

  def closed_cases
    @cases = @global_nav_manager.current_cases_finder.cases
  end

  def incoming_cases
    @cases = @global_nav_manager.current_cases_finder.cases
  end

  def my_open_cases
    @cases = @global_nav_manager.current_cases_finder.cases
    render :index
  end

  def open_cases
    @cases = @global_nav_manager.current_cases_finder.cases
    render :index
  end

  def new
    authorize Case, :can_add_case?

    @case = Case.new
    render :new
  end

  def create
    authorize Case, :can_add_case?

    @case = Case.new(create_foi_params)
    if create_foi_params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      render :new
    elsif @case.save
      if create_foi_params[:flag_for_disclosure_specialists] == 'yes'
        CaseFlagForClearanceService.new(user: current_user, kase: @case).call
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
      redirect_to edit_case_assignment_path @case, @case.assignments.last.id
    else
      set_permitted_events
      @accepted_now = params[:accepted_now]
      render :show
    end
  end

  def edit
    render :edit
  end

  def new_response_upload
    authorize @case, :can_add_attachment_to_flagged_and_unflagged_cases?
  end

  def upload_responses
    authorize @case, :can_add_attachment_to_flagged_and_unflagged_cases?
    rus = ResponseUploaderService.new(@case, current_user, params)
    rus.upload!
    case rus.result
    when :blank
      flash.now[:alert] = t('alerts.response_upload_blank?')
      render :new_response_upload
    when :error
      flash.now[:alert] = t('alerts.response_upload_error')
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

  def reassign_approver
    ars = ApproverReassignmentService.new(user: current_user, kase: @case)
    if ars.call == :ok
      flash[:notice] = 'Case re-assigned to you'
      redirect_to case_path(@case)
    else
      flash[:error] = 'You do not have rights to re-assign this case to you'
      redirect_to case_path(@case)
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
    CaseUnflagForClearanceService.new(user: current_user, kase: @case).call
  end

  def flag_for_clearance
    authorize @case, :can_flag_for_clearance?
    CaseFlagForClearanceService.new(user: current_user, kase: @case).call
  end

  def approve_response
    authorize @case, :can_approve_case?
    render :approve_response
  end

  def execute_response_approval
    authorize @case, :can_approve_case?
    result = CaseApprovalService.new(user: current_user, kase: @case).call
    raise Pundit::NotAuthorizedError if result == :unauthorised
    flash[:notice] = "You have cleared case #{@case.number} - #{@case.subject}."
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
      :subject, :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :flag_for_disclosure_specialists
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

  def set_s3_direct_post
    uploads_key = "uploads/#{@case.attachments_dir('responses')}/${filename}"
    @s3_direct_post = CASE_UPLOADS_S3_BUCKET.presigned_post(
      key:                   uploads_key,
      success_action_status: '201',
    )
  end

  def user_not_authorized(exception)
    case exception.query
    when :can_add_attachment?, :can_add_attachment_to_flagged_case?, :can_add_attachment_to_flagged_and_unflagged_cases?
      super(exception, case_path(@case))
    else
      super
    end
  end
end
