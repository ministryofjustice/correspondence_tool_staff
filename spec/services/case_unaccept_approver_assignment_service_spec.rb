require 'rails_helper'

describe CaseUnacceptApproverAssignmentService do
  let(:assigned_case)           { create :assigned_case, :flagged_accepted, approver: approver }
  let(:approver)                { dacu_disclosure.approvers.first }
  let(:dacu_disclosure)         { create :team_dacu_disclosure }
  let(:assignment)              { assigned_case.approver_assignments.first }
  let(:unaccepted_assignment)   { create :approver_assignment }
  let(:press_officer)           { find_or_create :press_officer }
  let(:press_office)            { press_officer.approving_team }

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

    context 'dacu disclosure assignment' do
      let(:service) {
        described_class.new assignment: assignment }

      it 'changes the state of the assignment to approved' do
        service.call
        expect(assignment).to have_received :pending!
      end

      it 'triggers an event on the case' do
        expect(assignment.case.state_machine).to receive(:unaccept_approver_assignment!).with(approver, dacu_disclosure)
        service.call
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

    context 'press office assignment' do
      let(:assigned_to_press_office_case) { create :assigned_case,
                                                   :flagged_accepted,
                                                   :press_office,
                                                   approver: press_officer }
      let(:press_office_assignment) do
        assigned_to_press_office_case
          .approver_assignments
          .where(team_id: press_office.id,
                 user_id: press_officer.id)
          .first
      end
      let(:dacu_disclosure_assignment) do
        assigned_to_press_office_case
          .approver_assignments
          .where(team_id: dacu_disclosure.id)
          .first
      end
      let(:service) { CaseUnacceptApproverAssignmentService.new(assignment: press_office_assignment) }

      it 'deletes approver assignments' do
        service.call
        expect(assigned_to_press_office_case.approver_assignments).to be_empty
      end

      it 'triggers an unflag event on the case for press office' do
        state_machine = press_office_assignment.case.state_machine
        allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
        service.call
        expect(state_machine)
          .to have_received(:unflag_for_clearance!)
                .with(press_officer, press_office, press_office)
      end

      it 'triggers an unflag event on the case for dacu disclosure' do
        state_machine = press_office_assignment.case.state_machine
        allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
        service.call
        expect(state_machine)
          .to have_received(:unflag_for_clearance!)
                .with(press_officer, press_office, dacu_disclosure)
      end

      it 'sets the result to ok and returns true' do
        expect(service.call).to be true
        expect(service.result).to eq :ok
      end

    end
  end
end
