class CaseRequestAmendsService
  attr_accessor :result
  attr_accessor :error

  def initialize(user:, kase:)
    @user = user
    @kase = kase
    @result = :incomplete
    @state_machine = @kase.state_machine
  end

  def call
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @state_machine.request_amends!(@user, assignment)
    end

    @result = :ok
  end
end
