class ApproverReassignmentService

  def initialize(user:, kase:)
    @kase  = kase
    @user = user
    @policy = Pundit.policy!(user, kase)
  end

  def call
    if @policy.can_reassign_approver?
      ActiveRecord::Base.transaction do
        assignment = @kase.approver_assignment
        @kase.state_machine.reassign_approver!(@user, @kase.approver, @kase.approving_team)
        assignment.update(user_id: @user.id)
        @kase.reload
        :ok
      end
    else
      :unauthorised
    end

  end
end
