class TeamDeletionService

  attr_reader :result

  def initialize(params)
    @team = Team.find(params[:id])
    @result = :incomplete
  end

  def call
    unless @team.has_active_children?
      ActiveRecord::Base.transaction do
        begin
          update_name
          soft_delete
          @result = :ok
        rescue
          @result = :error
        end
      end
    end
  end

  private

  def soft_delete
    @team.update_attributes!(deleted_at: Time.current)
  end

  def update_name
    @team.update_attributes!(name: "DEACTIVATED #{@team.name} " + Time.now.to_s)
  end
end
