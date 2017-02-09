class CasesController < ApplicationController

  before_action :set_case, only: [:close, :edit, :new_response_upload, :show, :update, :upload_responses]
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

  def show;
    @accepted_now = params[:accepted_now]
  end

  def edit
    render :edit
  end

  def new_response_upload
    authorize @case, :can_add_attachment?
  end

  def upload_responses
    authorize @case, :can_add_attachment?

    attachments = params[:attachment_url].reject(&:blank?).map do |url|
      CaseAttachment.new(
        type: params[:type],
        url: URI.encode(url)
      )
    end

    if attachments.all?(&:valid?)
      @case.attachments << attachments
      redirect_to case_path
    else
      flash.now[:alert] = 'Errors detected with uploaded files.'
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

    @case.close(current_user.id)
    flash[:notice] = t('notices.case_closed')
    render :show
  end

  def search
    @case = Case.search(params[:search])
    render :index
  end

  private

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
    @s3_direct_post = CASE_UPLOADS_S3_BUCKET.presigned_post(
      key:                   "#{@case.attachments_dir('responses')}/${filename}",
      success_action_status: '201',
      acl:                   'public-read'
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
