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

  def associated_teams(for_team:)
    case for_team
    when Team.private_office
      [{
         team: Team.dacu_disclosure,
         user: nil
       },
       {
         team: Team.press_office,
         user: User.find_by!(full_name: Settings.press_office_default_user)
       }]
    when Team.press_office
      [{
         team: Team.dacu_disclosure,
         user: nil
       }]
    else
      []
    end
  end

  private

  def config_for_case
    cat = @case.category.abbreviation.downcase
    Settings["#{cat}_cases"]
  end
end
