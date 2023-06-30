class CaseAcceptApproverAssignmentService
  attr_accessor :result, :error

  def initialize(assignment:, user:)
    @assignment = assignment
    @team = @assignment.team
    @user = user
    @result = :incomplete
  end

  def call
    return false unless validate_still_pending

    begin
      @assignment.case.state_machine.accept_approver_assignment!(acting_user: @user, acting_team: @team)
      @assignment.user = @user
      @assignment.accepted!
      @assignment.save!
      @result = :ok
      true
    rescue StandardError => e
      Rails.logger.debug { ">>>>>>>>>>>> error #{e.class} #{__FILE__}:#{__LINE__} <<<<<<<<<<<<\n" }
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace
      raise
    end
  end

private

  def validate_still_pending
    if @assignment.pending?
      true
    else
      @result = :not_pending
      false
    end
  end
end
