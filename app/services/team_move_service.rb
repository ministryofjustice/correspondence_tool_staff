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
  attr_reader :business_unit, :target_directorate, :new_unit

  def initialize(business_unit, target_directorate)
    @business_unit             = business_unit
    @target_directorate        = target_directorate
    @new_unit                  = transfer_team
  end

  private

  def transfer_team
    raise TeamNotBusinessUnitError.new if @business_unit.type != 'BusinessUnit'
    raise InvalidDirectorateError.new if @target_directorate.type != 'Directorate'
    raise OriginalDirectorateError.new if @target_directorate == business_unit.directorate

    @new_unit = @business_unit.dup
    @new_unit.directorate = target_directorate
    @new_unit.name << " (Moved from #{@business_unit.directorate.name})"
    @new_unit.correspondence_type_roles = @business_unit.correspondence_type_roles
    @new_unit.properties = @business_unit.properties
    @new_unit.user_roles = @business_unit.user_roles
    @business_unit.user_roles.delete_all   
    @new_unit.save
    @new_unit
  end
end
