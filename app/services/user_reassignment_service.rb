class UserReassignmentService

  def initialize(target_user:, acting_user:, kase:, target_assignment:)
    @target_user = target_user
    @acting_user = acting_user
    @kase  = kase
    @target_assignment = target_assignment
  end

  def call
    ActiveRecord::Base.transaction do
      #Add an entry in transitions table
      @kase.state_machine.reassign_user!(target_user: @target_user,
                                         target_team: acting_team,
                                         acting_user: @acting_user,
                                         acting_team: acting_team)

      #Update the assignment
      @target_assignment.update(user_id: @target_user.id)

      @kase.reload
      :ok
    end
  end

  private

  def acting_team
    if @acting_user.responder?
      @acting_user.responding_teams.first
    elsif @acting_user.approver?
      @acting_user.approving_team
    end
  end
end
