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
    ActiveRecord::Base.transaction do
      assignment = @kase.approver_assignments
                     .with_teams(@user.approving_team)
                     .first
      @state_machine.approve!(@user, assignment)
      assignment.update!(approved: true)
    end

    @result = :ok
  end
end
