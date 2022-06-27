
class TeamFinderService

  class UserNotFoundError < RuntimeError
    def initialize(team_finder_service)
      user = team_finder_service.user
      kase = team_finder_service.kase
      role = team_finder_service.assignment_role
      super("No accepted assignment with role '#{role}' for user #{user.id} on case #{kase.id}")
    end
  end

  class AssignmentNotFound < RuntimeError
    def initialize(team_finder_service)
      kase = team_finder_service.kase
      role = team_finder_service.assignment_role
      super ("No accepted assignment found for case #{kase} with role '#{role}'")
    end
  end

  TEAM_ROLES = {
      manager: :managing,
      responder: :responding,
      approver: :approving
  }.freeze

  attr_reader :kase, :user, :assignment_role

  def initialize(kase, user, team_role)
    @kase             = kase
    @user             = user
    @team_role        = team_role
    @assignment_role  = translate_role_for_assignment
  end

  # returns the team for the named user on the case. The user must have been an assigned user
  # on the case, or a TeamFinderService::UserNotFound error is raised
  #
  def team_for_user
    assigned_teams = @kase.assignments.where(role: @assignment_role).map(&:team)
    raise UserNotFoundError.new(self) if assigned_teams.empty?
    user_teams = @user.team_roles.where(role: @team_role).map(&:team)
    (assigned_teams & user_teams).first
  end

  #
  def team_for_assigned_user
    assignments = @kase.assignments.accepted.where(user_id: @user.id, role: @assignment_role)
    raise UserNotFoundError.new(self) if assignments.empty?
    assignments.singular.team
  end

  # returns the team for the user, where the team is accepted for the specified role in the case assignments
  #
  def team_for_unassigned_user
    assigned_teams = @kase.assignments.where(state: [:accepted, :pending], role: @assignment_role).map(&:team)
    raise UserNotFoundError.new(self) if assigned_teams.empty?
    user_teams = @user.team_roles.where(role: @team_role).map(&:team)
    (assigned_teams & user_teams).first
  end

  private

  def translate_role_for_assignment
    raise ArgumentError.new('Invalid role') unless @team_role.in?(TEAM_ROLES.keys)
    TEAM_ROLES[@team_role]
  end
end
