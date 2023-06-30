require "rails_helper"

describe AssignNewTeamService do
  let(:manager)             { create :manager }
  let(:team_dacu_bmt)       { find_or_create :team_dacu }
  let(:kase)                { create :assigned_case, :flagged, responding_team: }
  let(:responding_team)     { create :responding_team }
  let(:new_responding_team) { create :responding_team }
  let(:assignment)          { kase.responder_assignment }
  let(:notify_service)      { instance_double(NotifyNewAssignmentService, run: true) }

  describe ".new" do
    it "raises if the case responder assignment doesnt match the param" do
      expect {
        described_class.new(manager, { id: (assignment.id + 1), case_id: kase.id, team_id: responding_team.id })
      }.to raise_error RuntimeError, "Assignment mismatch"
    end

    it "does not raise if responder assignment id matches pararm" do
      expect {
        described_class.new(manager, { id: assignment.id, case_id: kase.id, team_id: responding_team.id })
      }.not_to raise_error
    end
  end

  describe "#call" do
    let(:service) { described_class.new(manager, { id: assignment.id, case_id: kase.id, team_id: new_responding_team.id }) }

    before do
      allow(NotifyNewAssignmentService).to receive(:new).and_return(notify_service)
      allow(notify_service).to receive(:run).and_return(true)
    end

    it "returns ok" do
      service.call
      expect(service.result).to eq :ok
      expect(notify_service).to have_received(:run)
    end

    it "updates the assignment with the new team id and state" do
      service.call
      assignment.reload
      expect(assignment.state).to eq "pending"
      expect(assignment.team_id).to eq new_responding_team.id
      expect(assignment.user_id).to be_nil
    end

    it "changes the state of the case" do
      service.call
      expect(kase.current_state).to eq "awaiting_responder"
    end

    it "creates a transition" do
      expect { service.call }.to change { kase.transitions.count }.by(1)
      tr = kase.transitions.last
      expect(tr.event).to eq "assign_to_new_team"
      expect(tr.to_state).to eq "awaiting_responder"
      expect(tr.most_recent).to be true
      expect(tr.acting_user_id).to eq manager.id
      expect(tr.acting_team_id).to eq team_dacu_bmt.id
      expect(tr.target_user_id).to be_nil
      expect(tr.target_team_id).to eq new_responding_team.id
    end
  end

  context "when closed case" do
    it "does not send an email" do
      kase = create :closed_case
      assignment = kase.responder_assignment
      service = described_class.new(manager, { id: assignment.id, case_id: kase.id, team_id: new_responding_team.id })
      service.call
      expect(notify_service).not_to have_received(:run)

      expect(service.result).to eq :ok
    end
  end
end
