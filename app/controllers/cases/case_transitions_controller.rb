module Cases
  class CaseTransitionsController < CasesController
    before_action :set_case, except: []
    before_action :set_date_of_birth_instance_var, except: []

    def mark_as_waiting_for_data
      @case.state_machine.mark_as_waiting_for_data!(params_for_transition)
      reload_case_page_on_success
    end

    def mark_as_ready_for_vetting
      @case.state_machine.mark_as_ready_for_vetting!(params_for_transition)
      reload_case_page_on_success
    end

    def mark_as_vetting_in_progress
      @case.state_machine.mark_as_vetting_in_progress!(params_for_transition)
      reload_case_page_on_success
    end

    def mark_as_ready_to_copy
      @case.state_machine.mark_as_ready_to_copy!(params_for_transition)
      reload_case_page_on_success
    end

    def mark_as_ready_to_dispatch
      @case.state_machine.mark_as_ready_to_dispatch!(params_for_transition)
      reload_case_page_on_success
    end

    def mark_as_closed
      @case.state_machine.mark_as_closed!(params_for_transition)
      reload_case_page_on_success
    end

    private

    def params_for_transition
      {acting_user: current_user, acting_team: current_user.managing_teams.first}
    end

    def set_case
      @case = Case::Base.find(params[:id])
      authorize @case
    end

    def reload_case_page_on_success
      flash[:notice] = t('cases.update.case_updated')
      redirect_to case_path(@case)
    end

    # this method is here to fix an issue with the gov_uk_date_fields
    # where the validation fails since the internal list of instance
    # variables lacks the date_of_birth field from the json properties
    def set_date_of_birth_instance_var
      @case.date_of_birth = @case.date_of_birth
    end
  end
end
