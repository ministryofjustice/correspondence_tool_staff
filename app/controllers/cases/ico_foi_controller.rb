module Cases
  class IcoFoiController < IcoController

    before_action -> { set_decorated_case(params[:id]) }, only: [:record_further_action, :require_further_action, :confirm_record_further_action, :confirm_require_further_action]

    def record_further_action
      authorize @case, :can_record_further_action?
    
      set_permitted_events
      read_info_from_session
      @s3_direct_post = S3Uploader.for(@case, 'requests')
      render 'cases/ico_foi/record_further_action'
    end

    def confirm_record_further_action
      authorize @case, :can_record_further_action?
      set_permitted_events
      if params_valid?
        session_persist_state(params_for_record_further_action)
        redirect_to require_further_action_case_ico_foi_path(@case)
      else
        @case = @case.decorate
        @s3_direct_post = S3Uploader.for(@case, 'requests')
        render :record_further_action
      end
    end

    def require_further_action
      authorize @case, :can_require_further_action?
    
      set_permitted_events
      render 'cases/ico_foi/require_further_action'
    end

    def confirm_require_further_action
      authorize @case, :can_record_further_action?
      set_permitted_events

      service = CaseRequireFurtherActionService.new(
        current_user,
        @case,
        params_for_requiring_further_action
      )
      result = service.call
      if result == :ok
        case @case.current_state
        when "drafting"
          flash[:notice] = I18n.t('notices.case/ico.case_required_further_action_same_responder')
        when "awaiting_responder"
          flash[:notice] = I18n.t('notices.case/ico.case_required_further_action_same_team')
        else
          flash[:notice] = I18n.t('notices.case/ico.case_required_further_action_reassign')
        end
        clear_up_session
        redirect_to case_path(@case)
      else
        @case = @case.decorate
        flash[:error] = service.error_message
        render :require_further_action
      end
    end

    private 

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
        uploaded_request_files: [],
      )
    end
    
    def params_valid?
      @case.assign_attributes(params_for_record_further_action)
      @case.valid?
    end

    def session_info_key
      "ico_foi_requir_further_action"
    end

    def session_persist_state(params)
      session[session_info_key] ||= {}
      params ||= {}
      session[session_info_key].merge! params
    end

    def read_info_from_session
      if session[session_info_key].present?
        @case.assign_attributes(session[session_info_key])
      end
    end

    def clear_up_session
      session[session_info_key] = {}
    end

  end
end
