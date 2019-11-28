class TeamMoveService
  class OriginalDirectorateError < RuntimeError
    def initialize
      super("Cannot move to the original directorate")
    end
  end
  class InvalidDirectorateError < RuntimeError
    def initialize
      super("Cannot move a Business Unit to a team that is not a directorate")
    end
  end
  class TeamNotBusinessUnitError < RuntimeError
    def initialize
      super("Cannot move a team which is not a business unit")
    end
  end

  attr_reader :result, :new_team

  def initialize(team, directorate)
    @team = team
    @directorate = directorate
    @result = :incomplete
    raise TeamNotBusinessUnitError.new if @team.type != 'BusinessUnit'
    raise InvalidDirectorateError.new if @directorate.type != 'Directorate'
    raise OriginalDirectorateError.new if @directorate == team.directorate
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        move_team
        @result = :ok
      rescue
        @team.reload
        @result = :error
      end
    end
  end

  private

  def move_team
    @new_team = @team.dup
    @new_team.directorate = @directorate
    @new_team.name << " (Moved from #{@team.directorate.name})"
    @new_team.correspondence_type_roles = @team.correspondence_type_roles
    @new_team.properties = @team.properties
    @new_team.user_roles = @team.user_roles
    @team.destroy_related_user_roles!
    @new_team.save
    Assignment.where(case_id: @team.open_cases.ids).update_all(team_id: @new_team.id)
    # CaseTransition.where(acting_team: @team).update_all(acting_team_id: @new_team.team.id)

  end
end
