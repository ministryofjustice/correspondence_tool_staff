# The call method returns the first team that this case has an assignment for to
# the specified user with the specified role.
#
# If there are no assignments for that user/role, then it returns the first team
# in an intersection of the case's teams with that role and the user's team with that role.
#
class TeamFinderService

  TEAM_ROLES = {
      manager: :managing,
      responder: :responding,
      approver: :approving
  }.freeze


  def initialize(kase, user, team_role)
    @kase             = kase
    @user             = user
    @team_role        = team_role
    @assignment_role  = translate_role_for_assignment
  end


  def call
    case_assignment_team || case_and_user_team
  end

  private

  def translate_role_for_assignment
    raise ArgumentError.new('Invalid role') unless @team_role.in?(TEAM_ROLES.keys)
    TEAM_ROLES[@team_role]
  end

  def case_assignment_team
    @kase.assignments.where(user_id: @user.id, role: @assignment_role).first&.team
  end

  def case_and_user_team
    (@kase.teams.where(role: @team_role) & @user.teams.where(role: @team_role)).first
  end


end



# assignments.where(user_id: user.id).first&.team ||
#   (teams & user.teams).first
