module Cases
  class OffenderSarController < CasesController
    include NewCase
    include OffenderSARCasesParams

    before_action :set_case_types, only: [:new, :create]

    before_action -> { set_decorated_case(params[:id]) }, only: [
      :transition, :edit, :update
    ]

    def initialize
      super
      @correspondence_type = CorrespondenceType.offender_sar
      @correspondence_type_key = 'offender_sar'
      @creation_optional_flags = {}
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.current_step = params[:step]
      load_optional_flags_from_params
      @back_link = back_link_url
    end

    def create
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.creator = current_user #to-do Remove when we use the case create service
      @case.current_step = params[:current_step]
      load_optional_flags_from_params
      if steps_are_completed? 
        if @case.valid_attributes?(create_params) && @case.valid?
          create_case
        else
          render :new
        end
      else
        if @case.valid_attributes?(create_params)
          go_next_step
        else
          render :new
        end
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
        @case.state_machine.send(params[:transition_name] + '!', params_for_transition)
        reload_case_page_on_success
      else
        raise ArgumentError.new("Bad transition, the action #{params[:transition_name]}is not allowed.")
      end
    end

    def edit
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      @case.current_step = params[:step]
      apply_date_workaround
    end

    private

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
      @case.save
      assign_case_to_creator if @case.offender_sar_complaint?
      session[session_state] = nil
      flash[:notice] = "Case created successfully"
      redirect_to case_path(@case)
    end

    def assign_case_to_creator
      assign_service = CaseAssignToTeamMemberService
                              .new kase: @case,
                                   role: 'responding',
                                   user: current_user
      assign_service.call
    end

    def apply_date_workaround
      # an issue with the Gov UK Date Fields causes the fields to show up empty
      # on edit unless you assign to the :date_of_birth, and :request_dated fields before display
      @case.date_of_birth = @case.date_of_birth
      @case.request_dated = @case.request_dated
      @case.external_deadline = @case.external_deadline
    end

    def params_for_transition
      { acting_user: current_user, acting_team: @case.default_managing_team }
    end

    def reload_case_page_on_success
      flash[:notice] = t('cases.update.case_updated')
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
      request_dated_exists = values.fetch('request_dated', false)
      values['request_dated'] = nil unless request_dated_exists
      correspondence_type.new(values).decorate
    end

    def session_persist_state(params)
      session[session_state] ||= {}
      params ||= {}
      session[session_state].merge! params
    end

    def preserve_step_state
      @case.current_step = params['current_step']
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
      @creation_optional_flags.present? && @creation_optional_flags.values.all? {|x| x.present?}
    end
  
    def back_link_url
      "#{@case.case_route_path}/#{@case.get_previous_step}#{build_url_params_from_flags}"
    end

  end
end
