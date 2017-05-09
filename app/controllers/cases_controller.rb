class CasesController < ApplicationController
  before_action :set_case,
    only: [
      :close, :edit, :new_response_upload, :show, :update,
        :upload_responses, :respond, :confirm_respond,
        :process_closure
    ]
  before_action :set_s3_direct_post, only: [:new_response_upload, :upload_responses]

  def index
    @cases = policy_scope(Case.open.by_deadline).map(&:decorate)
  end

  def closed_cases
    @cases = policy_scope(Case.closed).map(&:decorate)
  end

  def incoming_cases
    team_cases = Case.waiting_to_be_accepted(*current_user.teams)
    @cases = policy_scope(team_cases).map(&:decorate)
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
        @case.flag_for_clearance(current_user)
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
    authorize @case, :can_add_attachment?
  end

  def upload_responses
    authorize @case, :can_add_attachment?
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
    when :can_add_attachment?
      super(exception, case_path(@case))
    else
      super
    end
  end
end
