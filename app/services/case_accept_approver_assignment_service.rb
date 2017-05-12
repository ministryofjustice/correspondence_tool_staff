class CaseAcceptApproverAssignmentService
  attr_accessor :result
  attr_accessor :error

  def initialize(assignment:, user:)
    @assignment = assignment
    @team = @assignment.team
    @user = user
    @result = :incomplete
  end

  def call
    return false unless validate_still_pending

    @assignment.case.state_machine.accept_approver_assignment!(@user, @team)
    @assignment.user = @user
    @assignment.accepted!
    @assignment.save!
    @result = :ok
    true
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
