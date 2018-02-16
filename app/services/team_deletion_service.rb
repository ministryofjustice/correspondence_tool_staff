class TeamDeletionService

  attr_reader :result

  def initialize(team)
    @team = team
    @result = :incomplete
  end

  def call
    ActiveRecord::Base.transaction do
      begin
        soft_delete
        @result = :ok
      rescue
        @team.reload
        @result = :error
      end
    end
  end

  private

  def soft_delete
    @team.update_attributes!(deleted_at: Time.current,
                             name: "DEACTIVATED #{@team.name} " + Time.now.to_s)
  end


end
