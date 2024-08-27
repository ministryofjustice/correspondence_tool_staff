class CaseAssignToTeamMemberService
  attr_reader :result, :assignment

  def initialize(kase:, role:, user:, target_user: nil)
    @case = kase
    @role = role
    @user = user
    @target_user = target_user || user
    @result = :incomplete
  end

  def call
    Assignment.connection.transaction do
      target_team = @target_user.responding_teams.first
      @assignment = @case.assignments.new(team: target_team, role: @role, user: @target_user)
      if @assignment.valid?
        managing_team = @user.responding_teams.first
        @case.state_machine.move_to_team_member!(
          acting_user: @user,
          acting_team: managing_team,
          target_team:,
          target_user: @target_user,
        )
        @assignment.accepted!
        @assignment.save!
        @result = :ok
      else
        @result = :could_not_create_assignment
      end
    end
    @result == :ok
  end
end
