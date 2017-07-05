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
      if @team.press_office?
        kase = @assignment.case
        disclosure_assignment = kase.assignments
                                  .with_teams(Team.dacu_disclosure)
                                  .first
        unassign_approver_assignment disclosure_assignment
        unassign_approver_assignment @assignment
      else
        unaccept_approver_assignment @assignment
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

  def unaccept_approver_assignment(assignment)
    assignment.case.state_machine.unaccept_approver_assignment!(@user, @team)
    assignment.user = nil
    assignment.pending!
    assignment.save!
  end

  def unassign_approver_assignment(assignment)
    kase = assignment.case
    kase.state_machine.unflag_for_clearance!(@user, @team, assignment.team)
    assignment.destroy
  end
end
