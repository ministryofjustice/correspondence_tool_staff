require "rails_helper"

describe CaseUnacceptApproverAssignmentService do
  let(:assigned_case)         { create :assigned_case, :flagged_accepted, approver: }
  let(:approver)              { dacu_disclosure.approvers.first }
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:assignment)            { assigned_case.approver_assignments.first }
  let(:unaccepted_assignment) { create :approver_assignment }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:press_officer)        { press_office.approvers.first }
  let!(:private_office)       { find_or_create :team_private_office }
  let!(:private_officer)      { private_office.approvers.first }

  describe "call" do
    before do
      allow(assignment).to receive(:pending!)
      allow(assignment.case.state_machine)
        .to receive(:accept_approver_assignment!)
    end

    it "validates that the assignment has been accepted" do
      service = described_class.new assignment: unaccepted_assignment
      expect(service.call).to be false
      expect(service.result).to eq :not_accepted
    end

    context "when dacu disclosure assignment" do
      let(:service) do
        described_class.new assignment:
      end

      it "changes the state of the assignment to approved" do
        service.call
        expect(assignment).to have_received :pending!
      end

      it "triggers an event on the case" do
        expect(assignment.case.state_machine).to receive(:unaccept_approver_assignment!).with(acting_user: approver, acting_team: dacu_disclosure)
        service.call
      end

      it "removes the user from the assignment" do
        service.call
        expect(assignment.user).to be nil
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

    context "when press office assignment" do
      let(:assigned_to_press_office_case) do
        create :assigned_case,
               :flagged_accepted,
               :taken_on_by_press
      end
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
      let(:service) { described_class.new(assignment: press_office_assignment) }

      context "and case is not previously flagged for clearance" do
        before do
          # press officer flagging it for themselves and flags for dacu disclosure as side effect
          create :flag_case_for_clearance_transition,
                 case: assigned_to_press_office_case,
                 acting_user_id: press_officer.id,            # user: press_officer
                 target_team_id: dacu_disclosure.id,          # approving_team: dacu_disclosure
                 acting_team_id: press_office.id              # managing_team: press_office

          # press office flagging it for themselves
          create :flag_case_for_clearance_transition,
                 case: assigned_to_press_office_case,
                 acting_user_id: press_officer.id,            # user: press_officer
                 acting_team_id: press_office.id,             # approving_team: press_office
                 target_team_id: press_office.id,             # managing_team: press_office
                 target_user_id: press_officer.id

          # press office flagging it for themselves and flags for private office as a side effect
          create :flag_case_for_clearance_transition,
                 case: assigned_to_press_office_case,
                 acting_user_id: press_officer.id,
                 acting_team_id: press_office.id,             # managing_team: press_office
                 target_user_id: private_officer.id,          # user: private_officer
                 target_team_id: private_office.id            # approving_team: private_office
        end

        it "deletes approver assignments" do
          service.call
          expect(assigned_to_press_office_case.approver_assignments).to be_empty
        end

        it "triggers an unflag event on the case for press office" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .to have_received(:unflag_for_clearance!)
                  .with(acting_user: press_officer, acting_team: press_office, target_team: press_office)
        end

        it "triggers an unflag event on the case for private office" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .to have_received(:unflag_for_clearance!)
                  .with(acting_user: press_officer, acting_team: press_office, target_team: private_office)
        end

        it "triggers an unflag event on the case for dacu disclosure" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .to have_received(:unflag_for_clearance!)
                  .with(acting_user: press_officer, acting_team: press_office, target_team: dacu_disclosure)
        end

        it "sets the result to ok and returns true" do
          expect(service.call).to be true
          expect(service.result).to eq :ok
        end
      end

      context "and case is already flagged by DACU Disclosure and Private Office" do
        before do
          # Alter the existing transition that was created in case setup so that
          # it wasn't taken-on by press.
          private_office_transition = assigned_to_press_office_case
                                        .transitions
                                        .where(event: :take_on_for_approval,
                                               target_team_id: private_office.id)
          private_office_transition.update acting_team_id: private_office.id, # rubocop:disable Rails/SaveBang
                                           acting_user_id: private_officer.id
        end

        it "deletes only assignments made by press office" do
          service.call
          approver_assignments =
            assigned_to_press_office_case.approver_assignments
          expect(approver_assignments.map(&:team))
            .to match_array [dacu_disclosure, private_office]
        end

        it "triggers an unflag event on the case for press office" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .to have_received(:unflag_for_clearance!)
                  .with(acting_user: press_officer, acting_team: press_office, target_team: press_office)
        end

        it "does not trigger unflag event on the case for dacu disclosure" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .not_to have_received(:unflag_for_clearance!)
                      .with(press_officer, press_office, dacu_disclosure)
        end

        it "does not trigger unflag event on the case for private office" do
          state_machine = press_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .not_to have_received(:unflag_for_clearance!)
                      .with(press_officer, press_office, private_office)
        end

        it "sets the result to ok and returns true" do
          expect(service.call).to be true
          expect(service.result).to eq :ok
        end
      end
    end

    context "when private office assignment" do
      let(:private_office_assignment) do
        assigned_to_private_office_case
          .approver_assignments
          .where(team_id: private_office.id,
                 user_id: private_officer.id)
          .first
      end
      let(:dacu_disclosure_assignment) do
        assigned_to_private_office_case
          .approver_assignments
          .where(team_id: dacu_disclosure.id)
          .first
      end
      let(:service) { described_class.new(assignment: private_office_assignment) }

      context "and case is not already flagged for clearance" do
        let(:assigned_to_private_office_case) do
          create :assigned_case,
                 :taken_on_by_private
        end

        it "deletes approver assignments" do
          service.call
          expect(assigned_to_private_office_case.approver_assignments).to be_empty
        end

        it "triggers an unflag event on the case for private office" do
          state_machine = private_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine).to have_received(:unflag_for_clearance!)
                                     .with(acting_user: private_officer,
                                           acting_team: private_office,
                                           target_team: private_office)
        end

        it "triggers an unflag event on the case for dacu disclosure" do
          state_machine = private_office_assignment.case.state_machine
          allow(state_machine).to receive(:trigger_event).with(any_args)
          service.call
          expect(state_machine).to have_received(:trigger_event)
                                     .with(event: :unflag_for_clearance,
                                           params: { acting_user: private_officer,
                                                     acting_team: private_office,
                                                     target_team: dacu_disclosure })
        end

        it "sets the result to ok and returns true" do
          expect(service.call).to be true
          expect(service.result).to eq :ok
        end
      end

      context "and case is already flagged for clearance by DACU Disclosure" do
        let(:assigned_to_private_office_case) do
          create :assigned_case,
                 :flagged_accepted,
                 :taken_on_by_private
        end

        it "deletes only the private office approver assignments" do
          service.call
          approver_assignments =
            assigned_to_private_office_case.approver_assignments
          expect(approver_assignments.first.team).to eq dacu_disclosure
          expect(approver_assignments.count).to eq 1
        end

        it "triggers an unflag event on the case for private office" do
          state_machine = private_office_assignment.case.state_machine
          allow(state_machine).to receive(:trigger_event).with(any_args)
          service.call
          expect(state_machine).to have_received(:trigger_event)
                                     .with(event: :unflag_for_clearance,
                                           params: { acting_user: private_officer,
                                                     acting_team: private_office,
                                                     target_team: private_office })
        end

        it "does not trigger unflag event on the case for dacu disclosure" do
          state_machine = private_office_assignment.case.state_machine
          allow(state_machine).to receive(:unflag_for_clearance!).with(any_args)
          service.call
          expect(state_machine)
            .not_to have_received(:unflag_for_clearance!)
                        .with(acting_user: private_officer, acting_team: private_office, target_team: dacu_disclosure)
        end

        it "sets the result to ok and returns true" do
          expect(service.call).to be true
          expect(service.result).to eq :ok
        end
      end
    end
  end
end
