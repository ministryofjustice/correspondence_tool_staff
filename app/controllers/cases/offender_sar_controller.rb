module Cases
  class OffenderSarController < CasesController
    include NewCase
    include OffenderSARCasesParams

    before_action :set_case_types, only: %i[new create]

    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action -> { set_decorated_case(params[:id]) }, only: %i[
      transition
      edit
      update
      move_case_back
      confirm_move_case_back
      record_reason_for_lateness
      confirm_record_reason_for_lateness
      confirm_update_partial_flags
      confirm_sent_to_sscl
      outstanding_information_received_date
      outstanding_confirm_information_received_date
    ]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def initialize
      super
      @correspondence_type = CorrespondenceType.offender_sar
      @correspondence_type_key = "offender_sar"
      @creation_optional_flags = {}
      get_reasons_for_lateness
    end

    def new
      permitted_correspondence_types
      @rejected = params["rejected"]
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.current_step = params[:step]
      load_optional_flags_from_params
      @back_link = back_link_url
    end

    def create
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.creator = current_user # to-do Remove when we use the case create service
      @case.current_step = params[:current_step]
      load_optional_flags_from_params

      if steps_are_completed?
        if @case.valid_attributes?(create_params) && @case.valid?
          create_case
        else
          render :new
        end
      elsif @case.valid_attributes?(create_params)
        go_next_step
      else
        render :new
      end
    end

    def edit_params
      create_offender_sar_params
    end

    def case_type
      Case::SAR::Offender
    end

    def create_params
      create_offender_sar_params
    end

    def update_params
      update_offender_sar_params
    end

    def process_closure_params
      process_offender_sar_closure_params
    end

    def respond_params
      respond_offender_sar_params
    end

    def process_date_responded_params
      respond_offender_sar_params
    end

    def cancel
      session[session_state] = nil
      redirect_to new_case_sar_offender_path
    end

    # Actions for specific workflow state transitions
    def transition
      authorize @case, :transition?

      set_permitted_events
      if @permitted_events.include?(params[:transition_name].to_sym)
        @case.state_machine.send("#{params[:transition_name]}!", params_for_transition)
        reload_case_page_on_success
      else
        raise ArgumentError, "Bad transition, the action #{params[:transition_name]}is not allowed."
      end
    end

    def confirm_update_partial_flags
      authorize @case, :can_edit_case?
      service = CaseUpdatePartialFlagsService.new(
        user: current_user,
        kase: @case,
        flag_params: flags_process(partial_case_flags_params),
      )
      service.call

      case service.result
      when :error
        if service.message.present?
          flash[:alert] = service.message
        end
        @case = @case.decorate
        preserve_step_state
        render "cases/edit" and return
      when :ok
        flash[:notice] = t("cases.update.case_partial_flag_updated")
      when :no_changes
        flash[:alert] = "No changes were made"
      end
      redirect_to case_path(@case) and return
    end

    def edit
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      @case.current_step = params[:step]
      apply_date_workaround
    end

    def move_case_back
      authorize @case, :can_move_case_back?
      render :move_case_back
    end

    def confirm_move_case_back
      authorize @case, :can_move_case_back?
      if params["extra_comment"].present?
        @case.state_machine.move_case_back!(params_for_move_case_back)
        flash[:notice] = "Case has been moved back."
        redirect_to case_path(@case) and return
      else
        flash.now[:alert] = "Please provide the reason for reverting the case back."
        render :move_case_back
      end
    end

    def record_reason_for_lateness
      check_authorization
      render :record_reason_for_lateness
    end

    def confirm_record_reason_for_lateness
      check_authorization
      begin
        validate_reason(record_reason_params)
        service = case_updater_service.new(current_user, @case, record_reason_params)
        service.call(get_extra_message_for_reason_for_lateness_field)

        if service.result == :error
          if service.error_message.present?
            flash[:alert] = service.error_message
          end
          render :record_reason_for_lateness
        end
        case service.result
        when :ok
          flash[:notice] = t("cases.update.case_updated")
        when :no_changes
          flash[:alert] = "No changes were made"
        end
        redirect_to case_path(@case) and return
      rescue InputValidationError => e
        flash.now[:alert] = e.message
        render :record_reason_for_lateness
      end
    end

    def confirm_sent_to_sscl
      authorize @case, :can_edit_case?
      service = CaseUpdateSentToSsclService.new(
        user: current_user,
        kase: @case,
        params: sent_to_sscl_params,
      )

      service.call

      case service.result
      when :error
        if service.message.present?
          flash[:alert] = service.message
        end
        @case = @case.decorate
        preserve_step_state
        render "cases/edit" and return
      when :ok
        flash[:notice] = t("cases.update.case_updated")
      when :no_changes
        flash[:alert] = "No changes were made"
      end
      redirect_to case_path(@case) and return
    end

    def confirm_outstanding_information_received_date
      @case = Case::Base.find_by(id: params[:id])
      authorize @case, :can_edit_case?

      received_date = params[:offender_sar].permit(:received_date_dd, :received_date_mm, :received_date_yyyy)
      service = case_updater_service.new(current_user, @case, received_date)
      service.call

      if service.result == :error
        if service.error_message.present?
          flash[:alert] = service.error_message
        end
        render :outstanding_information_received_date
      end
      case service.result
      when :ok
        flash[:notice] = t("cases.update.case_updated")
      when :no_changes
        flash[:alert] = "No changes were made"
      end

      redirect_to case_path(@case) and return
    end

  private

    def flags_process(flag_params)
      if is_reqired_clear_up_second_partial_flag(flag_params)
        if flag_params["further_actions_required"].present?
          flag_params.delete("further_actions_required")
        end
        flag_params = flag_params.merge("further_actions_required" => nil)
      end
      flag_params
    end

    def is_reqired_clear_up_second_partial_flag(flag_params)
      flag_params["is_partial_case"].present? && flag_params["is_partial_case"].to_s.downcase == "false"
    end

    def get_extra_message_for_reason_for_lateness_field
      if @case.reason_for_lateness.present?
        t("event.capture_reason_for_lateness_change")
      else
        t("event.capture_reason_for_lateness_add")
      end
    end

    def check_authorization
      if @case.reason_for_lateness.present?
        authorize @case, :can_edit_case?
      else
        authorize @case, :can_capture_reason_for_lateness?
      end
    end

    def get_reasons_for_lateness
      @reasons_for_lateness_items = CategoryReference.list_by_category(:reasons_for_lateness)
      @reasons_for_lateness = CategoryReference.list_by_category(:reasons_for_lateness).pluck(:id, :code).to_h
      @reason_of_other = @reasons_for_lateness_items.find_by(code: "other")
    end

    def steps_are_completed?
      @case.current_step == @case.steps.last
    end

    def go_next_step
      copy_params = create_params
      copy_params = @case.process_params_after_step(copy_params)
      session_persist_state(copy_params)
      get_next_step(@case)
      redirect_to "#{@case.case_route_path}/#{@case.current_step}#{build_url_params_from_flags}"
    end

    def create_case
      @case.save # rubocop:disable Rails/SaveBang
      assign_case_to_creator if @case.offender_sar_complaint?
      session[session_state] = nil
      flash[:notice] = "Case created successfully"
      redirect_to case_path(@case)
    end

    def assign_case_to_creator
      assign_service = CaseAssignToTeamMemberService
                              .new kase: @case,
                                   role: "responding",
                                   user: current_user
      assign_service.call
    end

    def apply_date_workaround
      # an issue with the Gov UK Date Fields causes the fields to show up empty
      # on edit unless you assign to the :date_of_birth, and :request_dated fields before display
      @case.date_of_birth = @case.date_of_birth
      @case.request_dated = @case.request_dated
      @case.external_deadline = @case.external_deadline
      @case.external_deadline = @case.external_deadline
      @case.partial_case_letter_sent_dated = @case.partial_case_letter_sent_dated
      @case.sent_to_sscl_at = @case.sent_to_sscl_at
    end

    def params_for_transition
      { acting_user: current_user, acting_team: @case.default_managing_team }
    end

    def params_for_move_case_back
      message = "(Reason: #{params[:extra_comment]})"

      { acting_user: current_user, acting_team: @case.default_managing_team, message: }
    end

    def reload_case_page_on_success
      flash[:notice] = t("cases.update.case_updated")
      redirect_to case_path(@case)
    end

    # @todo: Should this be in Steppable?
    def get_next_step(obj)
      obj.current_step = params[:current_step]

      if params[:previous_button]
        obj.previous_step
      elsif params[:commit]
        obj.next_step
      end
    end

    def set_case_types
      @case_types = @correspondence_type.sub_classes.map(&:to_s)
    end

    # @todo the following are all related to session data (case) cross different page
    # maybe worthy having another class for handling such thing together in a more abstract way
    def build_case_from_session(correspondence_type)
      # regarding the `{ date_of_birth: nil }` below...
      # this is needed to prevent "NoMethodError undefined method `dd' for nil:NilClass"
      # when a new Case::SAR::Offender is being created from scratch, because the field is not
      # in the list of instance variables in the model at the point that the gov_uk_date_fields
      # is adding its magic methods. This manifests when running tests or after rails server restart
      values = session[session_state] || { date_of_birth: nil }

      # similar workaround needed for request dated
      request_dated_exists = values.fetch("request_dated", false)
      values["request_dated"] = nil unless request_dated_exists

      rejected_set_current_state(values)

      correspondence_type.new(values).decorate
    end

    def rejected_set_current_state(values)
      case params["rejected"]
      when "true"
        values["current_state"] = "rejected"
      when "false"
        values.delete("current_state")
      end
    end

    def session_persist_state(params)
      session[session_state] ||= {}
      params ||= {}
      session[session_state].merge! params
    end

    def preserve_step_state
      @case.current_step = params["current_step"]
    end

    def session_state
      "#{@correspondence_type_key}_state".to_sym
    end

    def load_optional_flags_from_params
      @creation_optional_flags.each do |key, _|
        @creation_optional_flags[key] = params[key]
      end
    end

    def build_url_params_from_flags
      if has_optional_flags?
        "?#{@creation_optional_flags.to_param}"
      else
        ""
      end
    end

    def has_optional_flags?
      @creation_optional_flags.present? && @creation_optional_flags.values.all?(&:present?)
    end

    def back_link_url
      if @case.get_previous_step
        "#{@case.case_route_path}/#{@case.get_previous_step}#{build_url_params_from_flags}"
      else
        new_case_path
      end
    end
  end
end
