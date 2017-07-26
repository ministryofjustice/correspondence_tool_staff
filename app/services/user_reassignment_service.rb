class UserReassignmentService
  def initialize(assignment:,
                 target_user:,
                 acting_user:,
                 target_team: nil,
                 acting_team: nil)
    @assignment  = assignment
    @kase        = assignment.case
    @target_user = target_user
    @acting_user = acting_user
    @target_team = target_team || @assignment.case.team_for_user(@target_user)
    @acting_team = acting_team || @assignment.case.team_for_user(@acting_user)
  end

  def call
    ActiveRecord::Base.transaction do
      #Add an entry in transitions table
      @kase.state_machine.reassign_user!(target_user: @target_user,
                                         target_team: @target_team,
                                         acting_user: @acting_user,
                                         acting_team: @acting_team)

      #Update the assignment
      @assignment.update(user_id: @target_user.id)
      :ok
    end
  end
end
