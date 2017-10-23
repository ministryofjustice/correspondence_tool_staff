class CaseUnflagForClearanceService
  attr_accessor :result

  def initialize(user:, kase:, team:, message:)
    @case = kase
    @user = user
    @team = team
    @message = message
    @result = :incomplete
    @dts = DefaultTeamService.new(kase)
  end

  def call
    # if eligible?
      @case.state_machine.unflag_for_clearance!(@user, @case.managing_team, @team, @message)
      @case.approver_assignments.with_teams(@team).destroy_all
      @result = :ok
    # else return @result
    # end
  end

  def self.eligible?(kase)
    kase.requires_clearance? && !kase.flagged_for_press_office_clearance?
  end

  private
  #
  # def flagged_for_press_or_private?
  #   @case.flagged_for_private_office_clearance? || @case.flagged_for_press_office_clearance?
  # end
  #
  # def eligible?
  #   @case.requires_clearance? && !flagged_for_press_or_private?
  # end
end
