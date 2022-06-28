class DirectorateMoveService
  
  class OriginalBusinessGroupError < RuntimeError
    def initialize
      super("Cannot move to the original Business Group")
    end
  end

  class InvalidBusinessGroupError < RuntimeError
    def initialize
      super("Cannot move a Directorate to a team that is not a Business Group")
    end
  end

  class NotDirectorateError < RuntimeError
    def initialize
      super("Cannot move a team which is not a Directorate")
    end
  end

  class FailedMoveTeamError < RuntimeError
    def initialize(team)
      super("Failed to move the team: #{team.name}")
    end
  end

  attr_reader :result, :new_teams, :new_directorate, :error_message

  def initialize(directorate, business_group)
    @business_group = business_group
    @directorate = directorate
    @result = :incomplete
    @new_teams = []
    @new_directorate = nil

    @error_message = nil

    raise NotDirectorateError.new unless @directorate.is_a? Directorate
    raise InvalidBusinessGroupError.new unless @business_group.is_a? BusinessGroup
    raise OriginalBusinessGroupError.new if business_group == directorate.business_group
  end

  def call
    begin
      ActiveRecord::Base.transaction do
        move_directorate!
        @result = :ok
      end
    rescue RuntimeError => err
      @directorate.reload
      @result = :error
      @error_message = err.message
    end
  end

  private

  def move_directorate!
    copy_directorate_to_directorate_team
    move_sub_teams
    deactivate_old_directorate
    link_old_directorate_to_new_one
    restore_new_directorate_name_to_original_name
  end

  def move_sub_teams
    @directorate.business_units.each do | team |
      service = TeamMoveService.new(team, @new_directorate)
      result = service.call
      raise FailedMoveTeamError.new(team) unless result == :ok
      @new_teams << service.new_team
    end
  end

  def copy_directorate_to_directorate_team
    @new_directorate = @directorate.dup
    @new_directorate.business_group = @business_group
    # Team.name does not allow duplicates on validation for active teams,
    #  so to allow us to save the new team we must give it a unique name
    @new_directorate.name = "(Moved from #{@directorate.name})"
    @new_directorate.code = "#{@directorate.code}-NEW" if @directorate.code.present?
    @new_directorate.properties = @directorate.properties
    @new_directorate.save
  end

  def deactivate_old_directorate
    # This will change the old directorate's name, to show deactivation
    service = TeamDeletionService.new(@directorate)
    service.call
  end

  def link_old_directorate_to_new_one
    # We do this for reporting purposes
    @directorate.moved_to_unit = @new_directorate
    @directorate.save
  end

  def restore_new_directorate_name_to_original_name
    # New directorate gets original directorate name to retain consistency for the users
    @new_directorate.name = @directorate.original_team_name
    @new_directorate.code = @new_directorate.code.sub(/-NEW$/, "") if @directorate.code.present?
    @new_directorate.save
  end

end
