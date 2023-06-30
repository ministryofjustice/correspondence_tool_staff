require "rails_helper"

describe "CurrentTeamAndUserICOTriggerService" do
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:responding_team)       { find_or_create :responding_team }
  let(:responder)             { find_or_create :foi_responder }
  let(:press_office)          { find_or_create :team_press_office }
  let(:press_officer)         { find_or_create :press_officer }
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:private_office)          { find_or_create :team_private_office }
  let(:private_officer)         { find_or_create :private_officer }
  let(:service) { CurrentTeamAndUserService.new(kase) }

  context "when responded state" do
    let(:kase)  { create :responded_ico_foi_case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "responded"
      expect(service.team).to eq team_dacu_disclosure
      expect(service.user).to eq disclosure_specialist
    end
  end

  context "when awaiting_dispatch" do
    # this does not create an ICO trigger case
    let(:kase)  { create :awaiting_dispatch_ico_foi_case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "awaiting_dispatch"
      expect(service.team).to eq team_dacu_disclosure
      expect(service.user).to eq disclosure_specialist
    end
  end
end
