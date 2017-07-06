require 'rails_helper'

describe DefaultTeamService do

  let!(:team_dacu)            { create :team_dacu}
  let!(:team_dacu_disclosure) { create :team_dacu_disclosure }
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
end


