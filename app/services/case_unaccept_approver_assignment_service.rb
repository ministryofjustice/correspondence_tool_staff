class CaseUnacceptApproverAssignmentService
  attr_accessor :result
  attr_accessor :error

  def initialize(assignment:)
    @assignment = assignment
    @user = @assignment.user
    @team = @assignment.team
    @result = :incomplete
  end

  def call
    return false unless validate_accepted
    ActiveRecord::Base.transaction do
      @assignment.case.state_machine.unaccept_approver_assignment!(@user, @team)
      if @team.dacu_disclosure?
        @assignment.user = nil
        @assignment.pending!
        @assignment.save!
      else
        @assignment.destroy
      end
      @result = :ok
      true
    end
  end

  private

  def validate_accepted
    if @assignment.accepted?
      true
    else
      @result = :not_accepted
      false
    end
  end
end
