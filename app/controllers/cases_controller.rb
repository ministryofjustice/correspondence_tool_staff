class CasesController < ApplicationController
  before_action :set_case,
    only: [
      :close, :edit, :new_response_upload, :show, :update,
        :upload_responses, :respond, :confirm_respond,
        :process_closure
    ]
  before_action :set_s3_direct_post, only: [:new_response_upload, :upload_responses]

  def index
    @cases = policy_scope(Case.by_deadline)
  end

  def new
    authorize Case, :can_add_case?

    @case = Case.new
    render :new
  end

  def create
    authorize Case, :can_add_case?

    @case = Case.new(create_foi_params)
    if @case.save
      flash[:notice] = t('.case_created')
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

    if policy(@case).can_accept_or_reject_case?
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

    responses = params[:uploaded_files].reject(&:blank?).map do |uploads_key|
      move_uploaded_response(uploads_key)
      CaseAttachment.find_or_initialize_by(
        type: 'response',
        key: response_destination_key(uploads_key)
      )
    end

    if responses.all?(&:valid?)
      responses.select(&:persisted?).each(&:touch)
      @case.add_responses(current_user.id, responses)
      remove_leftover_upload_files
      flash[:notice] = t('notices.response_uploaded')
      redirect_to case_path
    else
      flash.now[:alert] = t('alerts.response_upload_error')
      # @errors = attachments.reject(&:valid?).map { |a| a.errors.full_messages }.flatten
      render :new_response_upload
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
    @case.update(process_closure_params)
    if @case.valid?
      @case.close(current_user.id)
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
    @case.respond(current_user.id)
    flash[:notice] = t('.success')
    redirect_to cases_path
  end

  def search
    @case = Case.search(params[:search])
    render :index
  end

  private

  def set_permitted_events
    @permitted_events = @case.available_events.find_all do |event|
      case event
      when :assign_responder            then policy(@case).can_assign_case?
      when :add_responses               then policy(@case).can_add_attachment?
      when :respond                     then policy(@case).can_respond?
      when :close                       then policy(@case).can_close_case?
      end
    end
    @permitted_events ||= []
  end

  def process_closure_params
    params.require(:case).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      :outcome_name,
      :refusal_reason_name
    )
  end


  def process_closure_params
    params.require(:case).permit(
      :date_responded_dd, :date_responded_mm, :date_responded_yyyy
    ).merge(outcome_id: CaseClosure::Outcome.id_from_name(params['case']['outcome']))
  end


  def create_foi_params
    params.require(:case).permit(
      :requester_type,
      :name,
      :postal_address,
      :email,
      :subject, :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy
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

  def assign_params
    params.require(:case).permit(
      :user_id
    )
  end

  def set_case
    @case = Case.find(params[:id])
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

  def response_destination_key(uploads_key)
    "#{@case.attachments_dir('responses')}/#{File.basename(uploads_key)}"
  end

  def response_destination_path(uploads_key)
    "#{Settings.case_uploads_s3_bucket}/#{response_destination_key(uploads_key)}"
  end

  def move_uploaded_response(uploads_key)
    uploads_object = CASE_UPLOADS_S3_BUCKET.object(uploads_key)
    uploads_object.move_to response_destination_path(uploads_key)
  end

  def remove_leftover_upload_files
    prefix = "uploads/#{@case.id}"
    CASE_UPLOADS_S3_BUCKET.objects(prefix: prefix).each do |object|
      object.delete
    end
  end
end
