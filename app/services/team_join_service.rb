class TeamJoinService
  class TeamNotBusinessUnitError < RuntimeError
    def initialize
      super("Cannot move a team which is not a Business Unit")
    end
  end
  class InvalidTargetBusinessUnitError < RuntimeError
    def initialize
      super("Cannot join a Business Unit to a team that is not a Business Unit")
    end
  end
  class OriginalBusinessUnitError < RuntimeError
    def initialize
      super("Cannot join a Business Unit to itself")
    end
  end

  attr_reader :result, :target_team

  def initialize(team, target_team)
    @team = team
    @target_team = target_team
    @result = :incomplete

    raise TeamNotBusinessUnitError.new unless @team.is_a? BusinessUnit
    raise InvalidTargetBusinessUnitError.new unless @target_team.is_a? BusinessUnit
    raise OriginalBusinessUnitError.new if @team == @target_team
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        join_team!
        @result = :ok
      rescue
        @team.reload
        @result = :error
      end
    end
  end
  private

  def join_team!
    keep_users_for_original_teams
    join_users_to_new_team_history
    give_target_old_team_history
    move_associations_to_new_team
    deactivate_old_team
    link_old_team_to_new_team
  end
  def keep_users_for_original_teams
    @keep_user_roles = @team.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
    @keep_users_roles_target_team = @target_team.user_roles.as_json.map {|ur| [ur["team_id"], ur["user_id"], ur["role"]]}
  end
  def join_users_to_new_team_history
    @target_team.previous_teams.each do |pt|
      @keep_user_roles.each do |ur|
        TeamsUsersRole.create(team: Team.find(pt), user: User.find(ur[1]), role: ur[2]) unless @target_team.user_roles.where(team_id: pt, user_id: ur[1], role: ur[2]).count() > 0
      end
    end
    # Since previous_teams gives only the ids of historical teams,
    # we also need to add the joining users to the target team
    @keep_user_roles.each do |ur|
      TeamsUsersRole.create(team: @target_team, user: User.find(ur[1]), role: ur[2]) unless @target_team.user_roles.where(team_id: @target_team.id, user_id: ur[1], role: ur[2]).count > 0
    end
  end
  def give_target_old_team_history
    @team.previous_teams.each do |t|
      @keep_users_roles_target_team.each do |ur|
        TeamsUsersRole.create(team: Team.find(t), user: User.find(ur[1]), role: ur[2]) unless @team.user_roles.where(team_id: t, user_id: ur[1], role: ur[2]).count() > 0
      end
    end
    # Since previous_teams gives only the ids of historical teams,
    # we also need to add the target teams' users to the joining team
    @keep_users_roles_target_team.each do |ur|
      TeamsUsersRole.create(team: @team, user: User.find(ur[1]), role: ur[2]) unless @team.user_roles.where(team_id: @team.id, user_id: ur[1], role: ur[2]).count() > 0
    end
  end
  def move_associations_to_new_team
    Assignment.where(case_id: @team.open_cases.ids, team_id: @team.id).update_all(team_id: @target_team.id)
    CaseTransition.where(acting_team: @team).update_all(acting_team_id: @target_team.id)
    CaseTransition.where(target_team: @team).update_all(target_team_id: @target_team.id)
  end

  def deactivate_old_team
    # This will change the old team's name, to show deactivation
    service = TeamDeletionService.new(@team)
    service.call
  end

  def link_old_team_to_new_team
    # We do this for reporting purposes
    @team.moved_to_unit = @target_team
    @team.save
  end

end
