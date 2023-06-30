class DefaultTeamService
  def initialize(kase)
    @case = kase
  end

  def managing_team
    BusinessUnit.dacu_bmt
  end

  def approving_team
    BusinessUnit.dacu_disclosure
  end

  def associated_teams(for_team:)
    case for_team
    when BusinessUnit.private_office
      [{
        team: BusinessUnit.dacu_disclosure,
        user: nil,
      },
       {
         team: BusinessUnit.press_office,
         user: User.find_by!(email: default_press_officer),
       }]
    when BusinessUnit.press_office
      [{
        team: BusinessUnit.dacu_disclosure,
        user: nil,
      },
       {
         team: BusinessUnit.private_office,
         user: User.find_by!(email: default_private_officer),
       }]
    else
      []
    end
  end

private

  def default_press_officer
    @case.correspondence_type.default_press_officer
  end

  def default_private_officer
    @case.correspondence_type.default_private_officer
  end
end
