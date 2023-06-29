class AssignNewTeamService
  attr_reader :result

  def initialize(current_user, params)
    @user = current_user
    @case = Case::Base.find(params[:case_id])
    @assignment = @case.responder_assignment
    raise "Assignment mismatch" if @assignment.id != params[:id].to_i

    @team = BusinessUnit.find(params[:team_id])
    @managing_team = DefaultTeamService.new(@case).managing_team
    @result = :error
  end

  def call
    ActiveRecord::Base.transaction do
      @assignment.update!(state: "pending", team_id: @team.id, user_id: nil)
      @case.state_machine.assign_to_new_team!(acting_user: @user, acting_team: @managing_team, target_team: @team)
      @result = :ok
    end
  end
end
