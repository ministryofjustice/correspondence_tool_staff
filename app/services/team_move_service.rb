class TeamMoveService
  class InvalidDirectorate < RuntimeError
    def initialize(team_move_service)
      business_unit = team_move_service.business_unit
      target_directorate = team_move_service.target_directorate
      super ("Cannot move to the original directorate")
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
      raise InvalidDirectorate.new(self) if @target_directorate == business_unit.directorate
  end
end
