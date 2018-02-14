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
        @case.state_machine.unflag_for_clearance!(acting_user: @user,
                                                  acting_team: @case.managing_team,
                                                  target_team: @team,
                                                  message: @message)
        @case.approver_assignments.with_teams(@team).destroy_all
        @result = :ok
      end
    end
  rescue
    @result = :error
  end
end
