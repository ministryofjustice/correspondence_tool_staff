class CaseRequestAmendsService
  attr_accessor :result
  attr_accessor :error

  def initialize(user:, kase:, message:)
    @user = user
    @kase = kase
    @message = message
    @result = :incomplete
    @state_machine = @kase.state_machine
  end

  def call
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @state_machine.request_amends!(acting_user: @user, acting_team: assignment.team, message: @message)
    end

    @result = :ok
  end
end
