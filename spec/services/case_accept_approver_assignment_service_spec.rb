require 'rails_helper'

describe CaseAcceptApproverAssignmentService do
  let(:assigned_case)  { create :assigned_case, :flagged,
                                approving_team: approving_team }
  let(:approver)       { approving_team.approvers.first }
  let(:approving_team) { create :team_dacu_disclosure }
  let(:assignment)     { assigned_case.approver_assignment}
  let(:accepted_assignment) { create :approver_assignment, :accepted }

  describe 'call' do
    before do
      allow(assignment).to receive(:accepted!)
      allow(assignment.case.state_machine)
        .to receive(:accept_approver_assignment!)
    end

    it 'validates that the assignment is still pending' do
      service = described_class.new assignment: accepted_assignment,
                                    user: approver
      expect(service.call).to be false
      expect(service.result).to eq :not_pending
    end

    context 'succesful run' do
      let(:service) { described_class.new assignment: assignment,
                                          user: approver }

      it 'changes the state of the assignment to approved' do
        service.call
        expect(assignment).to have_received :accepted!
      end

      it 'triggers an event on the case' do
        service.call
        expect(assignment.case.state_machine)
          .to have_received(:accept_approver_assignment!)
                .with(approver, approving_team)
      end

      it 'adds the user to the assignment' do
        service.call
        expect(assignment.user).to be approver
      end

      it 'saves changes to assignment' do
        service.call
        expect(assignment.changed?).to be false
      end

      it 'sets the result to ok and returns true' do
        expect(service.call).to be true
        expect(service.result).to eq :ok
      end
    end
  end
end
