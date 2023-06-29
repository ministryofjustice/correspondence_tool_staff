require "rails_helper"

describe DefaultTeamService do
  let!(:team_dacu)            { find_or_create :team_dacu }
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:press_officer)        { find_or_create :default_press_officer }
  let!(:private_office)       { find_or_create :team_private_office }
  let!(:private_officer)      { find_or_create :default_private_officer }
  let(:kase)                  { create :case }
  let(:service)               { described_class.new(kase) }

  describe "#managing_team" do
    it "returns the team names in the settings file for this type of case" do
      expect(service.managing_team).to eq team_dacu
    end
  end

  describe "#approving_team" do
    it "returns the team names in the settings file for this type of case" do
      expect(service.approving_team).to eq team_dacu_disclosure
    end
  end

  describe "#associated_teams" do
    let(:dts) { described_class.new(kase) }

    it "returns DACU Disclosure and Private Office for Press Office" do
      expect(dts.associated_teams(for_team: press_office))
        .to match_array [{ team: team_dacu_disclosure, user: nil },
                         { team: private_office, user: private_officer }]
    end

    it "returns DACU Disclosure and Press Office for Private Office" do
      expect(dts.associated_teams(for_team: private_office))
        .to match_array [{ team: team_dacu_disclosure, user: nil },
                         { team: press_office,         user: press_officer }]
    end
  end
end
