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

  def can_deactivate_team?
    clear_failed_checks
    check_user_is_a_manager &&
        check_team_is_not_deactivated &&
        check_team_role_is_responding
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

  check :team_is_not_deactivated do
    @team.deleted_at.nil?
  end

  check :team_role_is_responding do
    @team.role == 'responder'
  end

end
