require "rails_helper"

describe CaseAcceptApproverAssignmentService do
  let(:assigned_case) do
    create :assigned_case, :flagged,
           approving_team: dacu_disclosure
  end
  let(:approver)        { dacu_disclosure.approvers.first }
  let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:assignment)      { assigned_case.approver_assignments.first }
  let(:accepted_assignment) { create :approver_assignment, :accepted }

  describe "call" do
    before do
      allow(assignment).to receive(:accepted!)
      allow(assignment.case.state_machine)
        .to receive(:accept_approver_assignment!)
    end

    it "validates that the assignment is still pending" do
      service = described_class.new assignment: accepted_assignment,
                                    user: approver
      expect(service.call).to be false
      expect(service.result).to eq :not_pending
    end

    context "succesful run" do
      let(:service) do
        described_class.new assignment:,
                            user: approver
      end

      it "changes the state of the assignment to approved" do
        service.call
        expect(assignment).to have_received :accepted!
      end

      it "triggers an event on the case" do
        service.call
        expect(assignment.case.state_machine)
          .to have_received(:accept_approver_assignment!)
                .with(acting_user: approver, acting_team: dacu_disclosure)
      end

      it "adds the user to the assignment" do
        service.call
        expect(assignment.user).to be approver
      end

      it "saves changes to assignment" do
        service.call
        expect(assignment.changed?).to be false
      end

      it "sets the result to ok and returns true" do
        expect(service.call).to be true
        expect(service.result).to eq :ok
      end
    end
  end
end
