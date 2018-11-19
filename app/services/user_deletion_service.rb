class UserDeletionService

  attr_reader :result

  def initialize(params)
    @user = User.find(params[:id])
    @team = BusinessUnit.find(params[:team_id])
    @result = :error
  end

  def call
    if @user.has_live_cases_for_team?(@team)
      unassign_cases
    end
    if @user.multiple_team_member?
      delete_memberships_of_team(@user, @team)
      @result = :ok
    else
      delete_user_if_not_member_of_other_team(@user, @team)
      @result = :ok
    end
  end

  private

  def delete_memberships_of_team(user, team)
    roles = TeamsUsersRole.where(user_id: user.id, team_id: team.id)
    roles.destroy_all
  end


  def delete_user_if_not_member_of_other_team(user, team)
    delete_memberships_of_team(user, team)
    user.soft_delete
  end

  def unassign_cases
    ActiveRecord::Base.transaction do
      @user.cases.opened.each do |kase|
        kase.responder_assignment.update!(state: 'pending', team_id: @team.id, user_id: nil)
        kase.state_machine.unassign_from_user!(acting_user: @user, acting_team: kase.managing_team)
        kase.update!(current_state: 'awaiting_responder')
      end
    end
  end
end
