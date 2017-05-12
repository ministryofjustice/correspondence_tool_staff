class CaseUnacceptApproverAssignmentService
  attr_accessor :result
  attr_accessor :error

  def initialize(assignment:)
    @assignment = assignment
    @team = @assignment.team
    @result = :incomplete
  end

  def call
    return false unless validate_accepted

    @assignment.user = nil
    @assignment.pending!
    @assignment.save!
    @result = :ok
    true
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
