class TeamPolicy < ApplicationPolicy

  attr_reader :user, :team, :failed_checks

  def initialize(user, team = nil)
    @user = user
    @team = team
    super(user, team)
  end

  def can_add_new_responder?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_member_of_team
  end

  def show?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_member_of_team
  end

  def edit?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_member_of_team
  end

  def update?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_member_of_team
  end

  def business_areas_covered?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_member_of_team
  end

  def create?
    clear_failed_checks
    check_user_is_a_manager
  end

  def new?
    clear_failed_checks
    check_user_is_a_manager
  end

  def destroy?
    clear_failed_checks
    check_user_is_a_manager && check_team_is_active && check_team_has_no_active_children
  end

  def move?
    clear_failed_checks
    check_user_is_a_manager
  end

  def join?
    clear_failed_checks
    check_user_is_a_manager
  end

  class Scope

    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.manager?
        scope.where(type: 'BusinessGroup')
      else
        scope.with_user(user)
      end
    end
  end

  check :user_is_member_of_team do
    team.in? user.teams
  end

  check :team_is_active do
    team.active?
  end

  check :team_has_no_active_children do
    !team.has_active_children?
  end

end
