class CaseUnflagForClearanceService
  attr_accessor :result

  def initialize(user:, kase:)
    @case = kase
    @user = user
    @result = :incomplete
  end

  def call
    return @result unless validate_case_is_flagged

    @case.state_machine.unflag_for_clearance!(@user, @case.managing_team)
    @case.approver_assignment.destroy
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
