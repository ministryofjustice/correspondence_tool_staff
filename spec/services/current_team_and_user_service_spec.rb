require "rails_helper"

describe "CurrentTeamAndUserService" do
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
  let(:responding_team)       { find_or_create :responding_team }
  let(:responder)             { find_or_create :foi_responder }
  let(:press_office)          { find_or_create :team_press_office }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_office)          { find_or_create :team_private_office }
  let(:private_officer)         { find_or_create :private_officer }
  let(:service) { CurrentTeamAndUserService.new(kase) }

  context "when unassigned state" do
    let(:kase)  { create :case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "unassigned"
      expect(service.team).to eq team_dacu
      expect(service.user).to be_nil
    end
  end

  context "when awaiting_responder state" do
    let(:kase)  { create :awaiting_responder_case, responding_team: }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "awaiting_responder"
      expect(service.team).to eq responding_team
      expect(service.user).to be_nil
    end
  end

  context "when drafting state" do
    let(:kase)  { create :case_being_drafted, responding_team:, responder: }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "drafting"
      expect(service.team).to eq responding_team
      expect(service.user).to eq responder
    end
  end

  context "when awaiting dispatch state" do
    let(:kase)  { create :case_with_response, responding_team:, responder: }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "awaiting_dispatch"
      expect(service.team).to eq responding_team
      expect(service.user).to eq responder
    end
  end

  context "when pending dacu_clearance state" do
    context "without assigned dacu disclosure team member" do
      let(:kase)  { create :pending_dacu_clearance_case }

      it "returns the correct team and user" do
        kase.approver_assignments.first.update!(user_id: nil)
        expect(kase.current_state).to eq "pending_dacu_clearance"
        expect(service.team).to eq team_dacu_disclosure
        expect(service.user).to eq nil
      end
    end

    context "with assigned dacu disclosure team member" do
      let(:kase)  { create :pending_dacu_clearance_case }

      it "returns the correct team and user" do
        expect(kase.current_state).to eq "pending_dacu_clearance"
        expect(service.team).to eq team_dacu_disclosure
        expect(service.user).to eq kase.approvers.first
      end
    end
  end

  context "when pending_press_office_clearance state" do
    let(:kase) do
      create :pending_press_clearance_case,
             press_officer:
    end

    it "returns the correct team and user" do
      kase.approver_assignments.first.update!(user_id: nil)
      expect(kase.current_state).to eq "pending_press_office_clearance"
      expect(service.team).to eq press_office
      expect(service.user).to eq press_officer
    end
  end

  context "when pending_private_office_clearance state" do
    let(:kase) do
      create :pending_private_clearance_case,
             private_officer:
    end

    it "returns the correct team and user" do
      kase.approver_assignments.first.update!(user_id: nil)
      expect(kase.current_state).to eq "pending_private_office_clearance"
      expect(service.team).to eq private_office
      expect(service.user).to eq private_officer
    end
  end

  context "when responded state" do
    let(:kase)  { create :responded_case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "responded"
      expect(service.team).to eq team_dacu
      expect(service.user).to be_nil
    end
  end

  context "when closed state" do
    let(:kase)  { create :closed_case }

    it "returns the correct team and user" do
      expect(kase.current_state).to eq "closed"
      expect(service.team).to be_nil
      expect(service.user).to be_nil
    end
  end

  context "when unknown_state" do
    let(:kase)  { create :closed_case }

    it "raises" do
      allow(kase).to receive(:current_state).and_return("of_disbelief")
      expect {
        service
      }.to raise_error(
        RuntimeError,
        "State of_disbelief unrecognised by CurrentTeamAndUser::Base",
      )
    end
  end
end
