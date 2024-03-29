module ReopenICOCase
  extend ActiveSupport::Concern

  included do
    before_action -> { set_decorated_case(params[:id]) }, only: %i[
      record_further_action
      require_further_action
    ]

    before_action -> { set_case(params[:id]) }, only: %i[
      confirm_record_further_action
      confirm_require_further_action
    ]
  end

  def record_further_action
    authorize @case, :can_record_further_action?

    set_permitted_events
    read_info_from_session
    @s3_direct_post = S3Uploader.for(@case, "requests")
    render "cases/ico/record_further_action"
  end

  def confirm_record_further_action
    authorize @case, :can_record_further_action?
    set_permitted_events
    if params_valid?
      session_persist_state(params_for_record_further_action)
      redirect_to require_further_action_case_ico_path(@case)
    else
      @case = @case.decorate
      @s3_direct_post = S3Uploader.for(@case, "requests")
      render :record_further_action
    end
  end

  def require_further_action
    authorize @case, :can_require_further_action?

    set_permitted_events
    init_deadlines
    render "cases/ico/require_further_action"
  end

  def confirm_require_further_action
    authorize @case, :can_record_further_action?
    set_permitted_events

    service = CaseRequireFurtherActionService.new(
      current_user,
      @case,
      params_for_requiring_further_action,
    )
    result = service.call
    if result == :ok
      flash[:notice] = prepare_flash_message
      clear_up_session
      redirect_to case_path(@case)
    else
      @case = @case.decorate
      flash.now[:alert] = service.error_message
      render :require_further_action
    end
  end

private

  def init_deadlines
    @case.internal_deadline = nil
    @case.external_deadline = nil
  end

  def prepare_flash_message
    case @case.current_state
    when "drafting"
      I18n.t("notices.case/ico.required_further_action.same_responder")
    when "awaiting_responder"
      I18n.t("notices.case/ico.required_further_action.same_team")
    else
      I18n.t("notices.case/ico.required_further_action.reassign")
    end
  end

  def params_for_record_further_action
    case_params = params.require(:ico)

    case_params.permit(
      :message,
      uploaded_request_files: [],
    )
  end

  def params_for_requiring_further_action
    case_params = params.require(:ico)
    case_params.merge! session[session_info_key] || {}
    case_params.permit(
      :message,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      :internal_deadline_dd, :internal_deadline_mm, :internal_deadline_yyyy,
      uploaded_request_files: []
    )
  end

  def params_valid?
    @case.assign_attributes(params_for_record_further_action)
    @case.valid?
  end

  def session_info_key
    "ico_foi_require_further_action"
  end

  def session_persist_state(params)
    session[session_info_key] ||= {}
    params ||= {}
    clear_up_files_params
    session[session_info_key].merge! params
  end

  def clear_up_files_params
    # The current implementation of front-end ui for uploading the files
    #  doesn't have the function of loading files which has been uploaded
    #  so we cannot keep this info in session
    if session[session_info_key].present?
      if session[session_info_key][:uploaded_request_files].present?
        session[session_info_key].delete(:uploaded_request_files)
      end
      if session[session_info_key]["uploaded_request_files"].present?
        session[session_info_key].delete("uploaded_request_files")
      end
    end
  end

  def read_info_from_session
    clear_up_files_params
    if session[session_info_key].present?
      @case.assign_attributes(session[session_info_key])
    end
  end

  def clear_up_session
    session[session_info_key] = {}
  end
end
