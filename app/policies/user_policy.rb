class UserPolicy < ApplicationPolicy
  attr_reader :user, :team, :failed_checks

  def initialize(user, team = nil)
    @user = user
    @team = team
    super(user, team)
  end

  def destroy?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_a_team_admin
  end

  check :user_is_a_team_admin do
    user.team_admin?
  end
end
