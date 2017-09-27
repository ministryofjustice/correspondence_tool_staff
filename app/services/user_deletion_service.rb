class UserDeletionService

  attr_reader :result

  def initialize(params)
    @user = User.find(params[:id])
    @team = BusinessUnit.find(params[:team_id])
    @result = :error
  end

  def call
    if @user.has_live_cases?
      @result = :has_live_cases
    else
      if @user.multiple_team_member?
        delete_memberships_of_team(@user, @team)
      else
        delete_user_if_not_member_of_other_team(@user, @team)
      end
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
end
