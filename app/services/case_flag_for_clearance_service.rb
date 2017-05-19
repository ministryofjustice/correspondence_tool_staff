class CaseFlagForClearanceService
  attr_accessor :result

  def initialize(user:, kase:)
    @case = kase
    @user = user
    @result = :incomplete
  end

  def call
    return @result unless validate_case_is_unflagged

    managing_team_name = Settings.foi_cases.default_managing_team
    managing_team = Team.managing.find_by(name: managing_team_name)
    disclosure_team_name = Settings.foi_cases.default_clearance_team
    approving_team = Team.approving.find_by(name: disclosure_team_name)
    @case.state_machine.flag_for_clearance! @user,
                                            managing_team,
                                            approving_team
    @case.approving_team = approving_team

    @result = :ok
  end

  private

  def validate_case_is_unflagged
    if !@case.requires_clearance?
      true
    else
      @result = :already_flagged
      false
    end
  end
end
