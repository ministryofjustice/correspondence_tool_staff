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

  # @note (Mohammed Seedat 2019-04-03)
  #   Deactivation information is stored in Team name string for reporting
  #   ease purposes. Note use of brackets to allow extraction of team name
  #   without additional information when required.
  def soft_delete
    deletion_date = DateTime.now.strftime('%F %T')

    @team.update!(
      deleted_at: Time.current,
      name: "#{Team::DEACTIVATED_LABEL} #{@team.name} @(#{deletion_date})"
    )
    @team.update_attribute(:code, "#{@team.code}-OLD-#{@team.id}") if @team.code.present?
  end
end
