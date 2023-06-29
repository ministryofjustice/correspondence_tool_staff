class CaseRequestAmendsService
  attr_accessor :result, :error

  def initialize(user:, kase:, message:, is_compliant:)
    @user = user
    @kase = kase
    @message = message
    @is_compliant = is_compliant
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @kase.state_machine.request_amends!(acting_user: @user, acting_team: assignment.team, message: @message)
      if @is_compliant
        @kase.log_compliance_date!
      end
    end

    @result = :ok
  end
end
