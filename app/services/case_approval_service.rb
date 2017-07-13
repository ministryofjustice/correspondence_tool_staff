class CaseApprovalService
  attr_accessor :result
  attr_accessor :error

  def initialize(user:, kase:)
    @user = user
    @kase = kase
    @result = :incomplete
    @state_machine = CaseStateMachine.new(@kase,
                                          transition_class: CaseTransition,
                                          association_name: :transitions)
  end

  def call
    case @kase.state_machine.next_approval_event
    when :approve
      mark_as_approved
    when :escalate_to_press_office
      escalate_to_press_office
    end

    @result = :ok
  end

  private

  def mark_as_approved
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @state_machine.approve!(@user, assignment)
      assignment.update!(approved: true)
    end
  end

  def escalate_to_press_office
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @state_machine.escalate_to_press_office!(@user, assignment)
      assignment.update!(approved: true)
    end
  end
end
