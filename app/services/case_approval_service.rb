class CaseApprovalService
  attr_accessor :result
  attr_accessor :error

  def initialize(user:, kase:)
    @user = user
    @kase = kase
    @result = :incomplete
    @state_machine = CaseStateMachine.new(@kase, transition_class: CaseTransition, association_name: :transitions)
  end

  def call
    if able_to_approve?
      mark_as_approved
      @result = :ok
    else
      @result = :unauthorised
    end
  end

  private

  def able_to_approve?
    policy = CasePolicy.new(@user, @kase)
    policy.can_approve_case?
  end

  def mark_as_approved
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments.for_user(@user).first
      assignment.update!(approved: true)
      @state_machine.methods
      @state_machine.approve!(@user, assignment)
    end
  end

end
