module Cases
  class CaseTransitionsController < CasesController
    def create
      @case = Case::Base.find(params[:case_id])
      authorize @case

      @case.state_machine.mark_as_waiting_for_data!(acting_user: current_user, acting_team: current_user.managing_teams.first)
    end
  end
end
