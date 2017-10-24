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
    begin
      ActiveRecord::Base.transaction do
        @case.state_machine.unflag_for_clearance!(@user, @case.managing_team, @team, @message)
        @case.approver_assignments.with_teams(@team).destroy_all
        @result = :ok
      end
    end
  rescue
    @result = :error
  end
end
