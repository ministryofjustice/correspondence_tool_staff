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
    begin
      ActiveRecord::Base.transaction do
        move_team!
        @result = :ok
      end
    rescue
      @team.reload
      @result = :error
    end
  end

  private

  def move_team!
    @new_team = @team.dup

    @new_team.directorate = @directorate
    @new_team.name << " (Moved from #{@team.directorate.name})"
    @new_team.correspondence_type_roles = @team.correspondence_type_roles
    @new_team.properties = @team.properties
    @new_team.user_roles = @team.user_roles

    @team.destroy_related_user_roles!
    @new_team.save!
  end
end
