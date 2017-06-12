require 'rails_helper'

describe CaseUnacceptApproverAssignmentService do
  let(:assigned_case)  { create :assigned_case, :flagged_accepted,
                                approver: approver }
  let(:approver)       { dacu_disclosure.approvers.first }
  let(:dacu_disclosure) { create :team_dacu_disclosure }
  let(:assignment)     { assigned_case.approver_assignments.first }
  let(:unaccepted_assignment) { create :approver_assignment }

  describe 'call' do
    before do
      allow(assignment).to receive(:pending!)
      allow(assignment.case.state_machine)
        .to receive(:accept_approver_assignment!)
    end

    it 'validates that the assignment has been accepted' do
      service = described_class.new assignment: unaccepted_assignment
      expect(service.call).to be false
      expect(service.result).to eq :not_accepted
    end

    context 'succesful run' do
      let(:service) { described_class.new assignment: assignment}

      it 'changes the state of the assignment to approved' do
        service.call
        expect(assignment).to have_received :pending!
      end

      xit 'triggers an event on the case' do
        service.call
        expect(assignment.case.state_machine)
          .to have_received(:accept_approver_assignment!)
                .with(approver, dacu_disclosure)
      end

      it 'removes the user from the assignment' do
        service.call
        expect(assignment.user).to be nil
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
