class TeamMoveService
  class OriginalDirectorateError < RuntimeError
    def initialize
      super("Cannot move to the original Directorate")
    end
  end

  class InvalidDirectorateError < RuntimeError
    def initialize
      super("Cannot move a Business Unit to a team that is not a Directorate")
    end
  end

  class TeamNotBusinessUnitError < RuntimeError
    def initialize
      super("Cannot move a team which is not a Business Unit")
    end
  end

  attr_reader :result, :new_team

  def initialize(team, directorate)
    @team = team
    @directorate = directorate
    @result = :incomplete

    raise TeamNotBusinessUnitError.new unless @team.is_a? BusinessUnit
    raise InvalidDirectorateError.new unless @directorate.is_a? Directorate
    raise OriginalDirectorateError.new if directorate == team.directorate
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        move_team!
        @result = :ok
      rescue
        @team.reload
        @result = :error
      end
    end
  end

  private

  def move_team!
    copy_team_to_new_team                      # New team gets temporary name to avoid duplication validation issue
    move_associations_to_new_team
    move_approver_assignments
    deactivate_old_team                        # Old team name gets amend to include deactivation text
    link_old_team_to_new_team
    restore_new_team_name_to_original_name     # New team gets original team name to retain consistency for the users
  end

  def copy_team_to_new_team
    @new_team = @team.dup
    @new_team.directorate = @directorate
    # Team.name does not allow duplicates on validation for active teams,
    #  so to allow us to save the new team we must give it a unique name
    @new_team.name = "(Moved from #{@team.directorate.name})"
    # Duplicate @team.code is a problem too
    @new_team.code = "#{@team.code}-NEW" unless @team.code.blank?
    @new_team.correspondence_type_roles = @team.correspondence_type_roles
    @new_team.properties = @team.properties
    @new_team.user_roles = @team.user_roles
    @new_team.save
  end

  def move_associations_to_new_team
    Assignment.where(case_id: @team.open_cases.ids, team_id: @team.id).update_all(team_id: @new_team.id)
    CaseTransition.where(acting_team: @team).update_all(acting_team_id: @new_team.id)
    CaseTransition.where(target_team: @team).update_all(target_team_id: @new_team.id)
  end

  def move_approver_assignments
    @team.assignments.approving.update_all(team_id: @new_team.id)
  end

  def deactivate_old_team
    # This will change the old team's name, to show deactivation
    service = TeamDeletionService.new(@team)
    service.call
  end

  def link_old_team_to_new_team
    # We do this for reporting purposes
    @team.moved_to_unit = @new_team
    @team.save
  end

  def restore_new_team_name_to_original_name
    # New team gets original team name to retain consistency for the users
    @new_team.name = @team.original_team_name
    @new_team.code = @new_team.code.sub(/-NEW$/, "") unless @team.code.blank?
    @new_team.save
  end
end
