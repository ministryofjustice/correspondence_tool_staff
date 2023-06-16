require "rails_helper"

describe CaseTeamCollection do
  context "unassigned case" do
    it "returns an empty array" do
      kase = find_or_create :foi_case
      expect(kase.current_state).to eq "unassigned"
      expect(kase.responding_team).to be_nil

      ctc = described_class.new(kase)
      expect(ctc.teams.size).to eq 1
      expect(kase.transitions.size).to eq 1
      expect(ctc.teams.first.id).to eq kase.transitions.first.acting_team_id
    end
  end

  context "responded case with multiple responder assignments" do
    let(:team_a)  { create :responding_team, name: "AAA" }
    let(:team_q)  { create :responding_team, name: "QQQ" }
    let(:team_z)  { create :responding_team, name: "ZZZ" }
    let(:kase)    { find_or_create :responded_case, :flagged_accepted, responding_team: team_q }

    it "returns an array of all teams in alphabetic order" do
      create :case_transition_assign_to_new_team, target_team: team_z, case_id: kase.id
      create :case_transition_assign_to_new_team, target_team: team_a, case_id: kase.id

      ctc = described_class.new(kase)
      expect(ctc.teams.map(&:name)).to eq [
        "AAA",
        "Disclosure",
        "Disclosure BMT",
        "QQQ",
        "ZZZ",
      ]
    end
  end
end
