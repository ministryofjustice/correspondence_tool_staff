class CaseFlagForClearanceService
  attr_accessor :result

  def initialize(user:, kase:, team: nil)
    @case = kase
    @user = user
    @team = team
    @result = :incomplete
  end

  def call
    return @result unless validate_case_is_unflagged

    managing_team_name = Settings.foi_cases.default_managing_team
    managing_team = Team.managing.find_by(name: managing_team_name)
    if @team.dacu_disclosure?
      @case.state_machine.flag_for_clearance! @user, managing_team, @team
      @case.approving_teams << @team
    else
      @case.state_machine.take_on_for_approval!(@user, @team)
      @case.approving_teams << @team
      @case.reload.approver_assignments.for_team(@team).last.update!(state: 'accepted', user_id: @user.id)  # only for press office
    end
    @result = :ok
  end

  private

  def validate_case_is_unflagged
    if !@case.approving_teams.include? @team
      true
    else
      @result = :already_flagged
      false
    end
  end
end
