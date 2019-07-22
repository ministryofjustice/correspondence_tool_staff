module Cases
  class CaseTransitionsController < CasesController
    def create
      @case = Case::Base.find(params[:case_id])
      authorize @case

      if @case.state_machine.mark_as_next_state!(acting_user: current_user, acting_team: current_user.managing_teams.first)
        redirect_to(case_path(@case))
      end
    end
  end
end
