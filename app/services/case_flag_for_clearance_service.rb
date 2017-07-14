class CaseFlagForClearanceService
  attr_accessor :result, :other_user

  def initialize(user:, kase:, team: nil)
    @case = kase
    @user = user
    @team = team
    @result = :incomplete
    @dts = DefaultTeamService.new(kase)
  end

  def call
    return @result unless validate_case_is_unflagged

    if @team.dacu_disclosure?
      assign_approver(@user, @team, @team)
    elsif @team.press_office?
      assign_and_accept_approver(@user, @team)
      if @case.approver_assignments.where(team: @dts.approving_team).blank?
        assign_approver(@user, @team, @dts.approving_team)
      end
    elsif @team.private_office?
      assign_and_accept_approver(@user, @team)
      if @case.approver_assignments.where(team: @dts.approving_team).blank?
        assign_approver(@user, @team, @dts.approving_team)
      end
    end
    @result = :ok
  end

  private

  def validate_case_is_unflagged
    if !@case.approving_teams.include? @team
      true
    else
      @result = :already_flagged
      @other_user = @case.approver_assignments.for_team(@team).first.user
      false
    end
  end

  def assign_approver(user, managing_team, team)
    @case.state_machine.flag_for_clearance! user,
                                            managing_team,
                                            team
    @case.approving_teams << team
  end

  def assign_and_accept_approver(user, team)
    @case.state_machine.take_on_for_approval!(user, team)
    @case.approving_teams << team
    @case.reload
    team_assignment = @case.approver_assignments.for_team(team).last
    team_assignment.update!(state: 'accepted', user_id: user.id)
  end
end
