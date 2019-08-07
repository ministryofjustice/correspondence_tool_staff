module Cases
  class OffenderSarController < CasesController
    include NewCase
    include OffenderSARCasesParams
    include GovUKDateFixes

    before_action :set_case_types, only: [:new, :create]
    before_action :set_case, except: [:new, :create]
    before_action :set_date_of_birth, except: [:new, :create]

    def initialize
      @correspondence_type = CorrespondenceType.offender_sar
      @correspondence_type_key = 'offender_sar'

      super
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      @case = OffenderSARCaseForm.new(session)
      step = params[:step].present? && params[:step] != 'new' ? params[:step] : @case.steps.first

      # @todo: Why does current_step need to be set? is it something OffenderSARCaseForm
      # can figure out itself?
      @case.current_step = step

      @case = OffenderSARCaseForm.new(session)
      @case.current_step = params[:step]
    end

    def create
      authorize case_type, :can_add_case?

      @case = OffenderSARCaseForm.new(session)
      @case.case.creator = current_user #to-do Remove when we use the case create service
      @case.case.subject = "Offender SAR" #to-do Remove when we use the case create service
      @case.assign_params(create_params) if create_params
      @case.current_step = params[:current_step]

      if !@case.valid_attributes?(create_params)
        render :new
      elsif @case.valid? && @case.save
        session[:offender_sar_state] = nil
        flash[:notice] = "Case created successfully"
        redirect_to case_path(@case.case)
      else
        @case.session_persist_state(create_params)
        get_next_step(@case)
        redirect_to "#{step_case_sar_offender_index_path}/#{@case.current_step}"
      end
    end

    def case_type
      Case::SAR::Offender
    end

    def create_params
      create_offender_sar_params
    end

    def edit_params
      edit_offender_sar_params
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
      session[:offender_sar_state] = nil
      redirect_to new_case_sar_offender_path
    end

    # Actions for specific workflow state transitions
    def transition
      available_actions = %w[
        mark_as_waiting_for_data
        mark_as_ready_for_vetting
        mark_as_vetting_in_progress
        mark_as_ready_to_copy
        mark_as_ready_to_dispatch
        mark_as_closed
      ]

      if available_actions.include?(params[:transition_name])
        @case.state_machine.send(params[:transition_name] + '!', params_for_transition)
        reload_case_page_on_success
      else
        raise ArgumentError.new('Bad transition')
      end
    end

    private

    def params_for_transition
      { acting_user: current_user, acting_team: current_user.managing_teams.first }
    end

    def set_case
      @case = Case::Base.find(params[:id])
      authorize @case
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
  end
end
