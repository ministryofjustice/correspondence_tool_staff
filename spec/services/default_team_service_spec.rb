require 'rails_helper'

describe DefaultTeamService do

  let!(:team_dacu)            { create :team_dacu}
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:press_officer)        { create :press_officer, full_name: 'Preston Offman' }
  let!(:private_office)       { find_or_create :team_private_office }
  let!(:private_officer)      { create :private_officer, full_name: 'Primrose Offord' }
  let(:kase)                  { create :case }
  let(:service)               { DefaultTeamService.new(kase) }

  describe '#managing_team' do
    it 'returns the team names in the settings file for this category of cases' do
      expect(service.managing_team).to eq team_dacu
    end
  end

  describe '#approving_team' do
    it 'returns the team names in the settings file for this category of cases' do
      expect(service.approving_team).to eq team_dacu_disclosure
    end
  end

  describe '#associated_teams' do
    let(:dts) { DefaultTeamService.new(kase) }

    it 'returns DACU Disclosure and Private Office for Press Office' do
      expect(dts.associated_teams(for_team: press_office))
        .to match_array [{team: team_dacu_disclosure, user: nil},
                         {team: private_office, user: private_officer}]
    end

    it 'returns DACU Disclosure and Press Office for Private Office' do
      expect(dts.associated_teams(for_team: private_office))
        .to match_array [{team: team_dacu_disclosure, user: nil},
                         {team: press_office,         user: press_officer}]
    end
  end
end


