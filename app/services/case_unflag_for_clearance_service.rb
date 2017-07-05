class CaseUnflagForClearanceService
  attr_accessor :result

  def initialize(user:, kase:, team:)
    @case = kase
    @user = user
    @team = team
    @result = :incomplete
  end

  def call
    return @result unless validate_case_is_flagged

    @case.state_machine.unflag_for_clearance!(@user, @case.managing_team, @team)
    @case.approver_assignments.with_teams(@team).destroy_all

    if @team.press_office?
      dacu_disclosure = Team.dacu_disclosure
      @case.state_machine.unflag_for_clearance!(@user, @case.managing_team, dacu_disclosure)
      @case.approver_assignments.with_teams(dacu_disclosure).destroy_all
    end

    @result = :ok
  end

  private

  def validate_case_is_flagged
    if @case.requires_clearance?
      true
    else
      @result = :not_flagged
      false
    end
  end
end
