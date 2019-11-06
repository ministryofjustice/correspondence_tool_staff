class TeamMoveService
  class OriginalDirectorateError < RuntimeError
    def initialize(team_move_service)
      business_unit = team_move_service.business_unit
      target_directorate = team_move_service.target_directorate
      super ("Cannot move to the original directorate")
    end
  end
  class InvalidDirectorateError < RuntimeError
    def initialize(team_move_service)
      business_unit = team_move_service.business_unit
      target_directorate = team_move_service.target_directorate
      super ("Cannot move a Business Unit to a team that is not a directorate")
    end
  end
  class TeamNotBusinessUnitError < RuntimeError
    def initialize(team_move_service)
      business_unit = team_move_service.business_unit
      target_directorate = team_move_service.target_directorate
      super ("Cannot move a team which is not a business unit")
    end
  end
  attr_reader :business_unit, :target_directorate, :new_unit

  def initialize(business_unit, target_directorate)
    @business_unit             = business_unit
    @target_directorate        = target_directorate
    @new_unit                  = transfer_team
  end

  private

  def transfer_team
    raise TeamNotBusinessUnitError.new( self ) if @business_unit.type != 'BusinessUnit'
    raise InvalidDirectorateError.new(self) if @target_directorate.type != 'Directorate'
    raise OriginalDirectorateError.new(self) if @target_directorate == business_unit.directorate

    @new_unit = @business_unit.dup
    @new_unit.directorate = target_directorate
    @new_unit.name << "Moved from #{@business_unit.directorate.name}"
    @new_unit.correspondence_type_roles = @business_unit.correspondence_type_roles
    @new_unit.save
    @new_unit
  end
end
