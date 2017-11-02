class TeamDeletionService

  attr_reader :result

  def initialize(params)
    @team = Team.find(params[:id])
    @result = :error
  end

  def call
    # if @team.has_active_children?
    #   @result = :has_live_children
    # else
      update_name
      @result = :ok
    # end
  end

  private

  def soft_delete
    @team.update_attribute(:deleted_at, Time.current)
  end

  def update_name
    @team.update_attribute(:name, "DEACTIVATED #{@team.name} " + Time.now.to_s)
  end
end
