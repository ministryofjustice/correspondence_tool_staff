class DefaultTeamService

  def initialize(kase)
    @case = kase
    @config = config_for_case
  end

  def managing_team
    Team.find_by_name! @config.default_managing_team
  end

  def approving_team
    Team.find_by_name! @config.default_clearance_team
  end

  private

  def config_for_case
    cat = @case.category.abbreviation.downcase
    Settings["#{cat}_cases"]
  end
end
