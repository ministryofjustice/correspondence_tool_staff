class TeamPolicy < ApplicationPolicy

  attr_reader :user, :team, :failed_checks

  def initialize(user, team = nil)
    @user = user
    super(user, team)
  end

  def can_add_new_responder?
    clear_failed_checks
    check_user_is_a_manager
  end

  def index?
    clear_failed_checks
    check_user_is_a_manager
  end

  def show?
    clear_failed_checks
    check_user_is_a_manager
  end
end
