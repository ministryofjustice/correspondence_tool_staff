class TeamJoinService
  class TeamNotBusinessUnitError < RuntimeError
    def initialize
      super("Cannot join a team which is not a Business Unit")
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

  class TeamHasCodeError < RuntimeError
    def initialize
      super("Cannot join a Business Unit that has a code defined")
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
    raise TeamHasCodeError.new if @team.code.present?
    raise TeamHasCodeError.new if @target_team.code.present?
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
    join_users_to_new_team_history
    give_target_old_team_history
    move_associations_to_new_team
    deactivate_old_team
    link_old_team_to_new_team
  end

  def create_role(team, ur)
    unless team.user_roles.where(user_id: ur.user.id, role: ur.role).present?
      TeamsUsersRole.create(team: team, user: ur.user, role: ur.role)
    end
  end

  def join_users_to_new_team_history
    @target_team.previous_teams.each do |previous_team|
      @team.user_roles.each do |user_role|
        create_role(previous_team, user_role)
      end
    end

    # Since previous_teams gives only the ids of historical teams,
    # we also need to add the joining users to the target team
    @team.user_roles.each do |user_role|
      create_role(@target_team, user_role)
    end
  end

  def give_target_old_team_history
    @team.previous_teams.each do |previous_team|
      @target_team.user_roles.each do |user_role|
        create_role(previous_team, user_role)
      end
    end

    # Since previous_teams gives only the ids of historical teams,
    # we also need to add the target teams' users to the joining team
    @target_team.user_roles.each do |user_role|
      create_role(@team, user_role)
    end
  end

  def move_associations_to_new_team
    Assignment.where(case_id: @team.assigned_open_cases.ids, team_id: @team.id).update_all(team_id: @target_team.id)
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
