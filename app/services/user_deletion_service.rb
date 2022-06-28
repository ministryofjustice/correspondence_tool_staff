class UserDeletionService

  attr_reader :result

  def initialize(params, acting_user)
    @target_user = User.find(params[:id])
    @acting_user = acting_user
    @team = BusinessUnit.find(params[:team_id])
    @result = :error
  end

  def call
    ActiveRecord::Base.transaction do
      if @target_user.has_live_cases_for_team?(@team)
        unassign_cases
      end
      if @target_user.multiple_team_member?
        delete_memberships_of_team
      else
        delete_user_if_not_member_of_other_team
      end
      @result = :ok
    end
  end

  private

  def delete_memberships_of_team
    team_ids = @team.previous_teams
    team_ids << @team.id

    roles = TeamsUsersRole.where(user_id: @target_user.id, team_id: team_ids)
    roles.destroy_all
  end

  def delete_user_if_not_member_of_other_team
    delete_memberships_of_team
    @target_user.soft_delete
  end

  def unassign_cases
    @target_user.cases.opened.each do |kase|
      unless kase.has_responded?
        kase.responder_assignment.update!(state: 'pending', team_id: @team.id, user_id: nil)
        kase.state_machine.unassign_from_user!(acting_user: @acting_user, acting_team: kase.managing_team)
        NotifyNewAssignmentService.new(team: @team, assignment: kase.responder_assignment).run
      end
    end
  end
end
