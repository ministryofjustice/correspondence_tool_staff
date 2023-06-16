require "rails_helper"

describe CaseFlagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) do
    create :assigned_case, :flagged,
           approving_team: dacu_disclosure
  end
  let(:approver)              { dacu_disclosure.approvers.first }
  let!(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }
  let!(:press_office)         { find_or_create :team_press_office }
  let!(:press_officer)        { find_or_create :default_press_officer }
  let!(:private_office)       { find_or_create :team_private_office }
  let!(:private_officer)      { find_or_create :default_private_officer }

  describe "call" do
    context "flagging by dacu disclosure" do
      context "case is already flagged" do
        let(:service) do
          described_class.new user: approver,
                              kase: assigned_flagged_case,
                              team: dacu_disclosure
        end

        it "validates whether the case is not flagged" do
          expect(service.call).to eq :already_flagged
          expect(service.result).to eq :already_flagged
        end
      end

      context "case is not flagged already" do
        let(:service) do
          described_class.new user: approver,
                              kase: assigned_case,
                              team: dacu_disclosure
        end

        before do
          allow(assigned_case.state_machine).to receive(:flag_for_clearance!)
        end

        it "triggers an event on the case state machine" do
          expect(assigned_case.state_machine).to receive(:flag_for_clearance!)
          service.call
        end

        it "assigns DACU disclosure as the approving team to the case" do
          service.call
          expect(assigned_case.approving_teams).to include dacu_disclosure
        end

        it "sets the result to ok and returns true" do
          expect(service.call).to eq :ok
          expect(service.result).to eq :ok
        end
      end
    end

    context "flagging for press office" do
      context "case is not already taken on by DACU Disclosure" do
        before do
          allow(assigned_case.state_machine).to receive(:flag_for_clearance!)
        end

        let(:service) do
          described_class.new user: press_officer,
                              kase: assigned_case,
                              team: press_office
        end

        it "returns ok when successful" do
          expect(service.call).to eq :ok
        end

        it "adds an accepted assignment for press office and press officer" do
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(press_office).first
          expect(assignment.state).to eq "accepted"
          expect(assignment.user_id).to eq press_officer.id
          expect(assignment.approved?).to be false
        end

        it "adds pending assignments for associated teams without user" do
          dts = instance_double DefaultTeamService,
                                associated_teams: [{ team: dacu_disclosure,
                                                     user: nil }]
          service.instance_variable_set :@dts, dts
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(dacu_disclosure)
                         .first
          expect(assignment.state).to eq "pending"
          expect(assignment.user_id).to be_nil
          expect(assignment.approved?).to be false
        end

        it "adds accepted assignments for associated teams with user" do
          dts = instance_double DefaultTeamService,
                                associated_teams: [{ team: private_office,
                                                     user: private_officer }]
          service.instance_variable_set :@dts, dts
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(private_office)
                         .first
          expect(assignment.state).to eq "accepted"
          expect(assignment.user_id).to eq private_officer.id
          expect(assignment.approved?).to be false
        end

        it "triggers a flag_for_clearance event on the case state machine" do
          # we have to use expect_any_instance here because the state machine on the case is re-initialised on
          # switch of workflow, which happens during service.call
          expect_any_instance_of(ConfigurableStateMachine::Machine).to receive(:flag_for_clearance!)
          service.call
        end

        it "returns :already_flagged if already taken on by the same team" do
          service.call
          expect(service.call).to eq :already_flagged
        end

        it "adds a transition record for press office assignment" do
          service.call
          tx = assigned_case.transitions.third
          expect(tx.event).to eq "take_on_for_approval"
          expect(tx.to_state).to eq "awaiting_responder"
          expect(tx.message).to be_nil
          expect(tx.acting_user_id).to eq press_officer.id
          expect(tx.acting_team_id).to eq press_office.id
        end

        it "triggers an event on the state machine" do
          expect(assigned_case.state_machine).to receive(:take_on_for_approval!).exactly(2)
          service.call
        end
      end

      context "case is already taken on by DACU Disclosure" do
        before do
          allow(assigned_flagged_case.state_machine)
            .to receive(:flag_for_clearance!)
        end

        let(:service) do
          described_class.new user: press_officer,
                              kase: assigned_flagged_case,
                              team: press_office
        end

        it "returns ok when successful" do
          expect(service.call).to eq :ok
        end

        it "adds an accepted assignment for press office and press officer" do
          service.call
          expect(assigned_flagged_case
                   .approver_assignments
                   .for_team(press_office)
                   .count).to eq 1
        end

        it "does not add an assignment for DACU disclosure" do
          service.call
          expect(assigned_flagged_case
                   .approver_assignments
                   .for_team(dacu_disclosure)
                   .count).to eq 1
        end
      end
    end

    context "flagging for private office" do
      context "case is not already taken on by DACU Disclosure" do
        before do
          allow(assigned_case.state_machine).to receive(:flag_for_clearance!)
        end

        let(:service) do
          described_class.new user: private_officer,
                              kase: assigned_case,
                              team: private_office
        end
        let(:machine) { assigned_case.state_machine }

        it "returns ok when successful" do
          expect(service.call).to eq :ok
        end

        it "adds an accepted assignment for private office and private officer" do
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(private_office).first
          expect(assignment.state).to eq "accepted"
          expect(assignment.user_id).to eq private_officer.id
          expect(assignment.approved?).to be false
        end

        it "adds pending assignments for associated teams without user" do
          dts = instance_double DefaultTeamService,
                                associated_teams: [{ team: dacu_disclosure,
                                                     user: nil }]
          service.instance_variable_set :@dts, dts
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(dacu_disclosure)
                         .first
          expect(assignment.state).to eq "pending"
          expect(assignment.user_id).to be_nil
          expect(assignment.approved?).to be false
        end

        it "adds accepted assignments for associated teams with user" do
          dts = instance_double DefaultTeamService,
                                associated_teams: [{ team: private_office,
                                                     user: private_officer }]
          service.instance_variable_set :@dts, dts
          service.call
          assignment = assigned_case.approver_assignments
                         .for_team(private_office)
                         .first
          expect(assignment.state).to eq "accepted"
          expect(assignment.user_id).to eq private_officer.id
          expect(assignment.approved?).to be false
        end

        it "triggers a flag_for_clearance event on the case state machine" do
          expect_any_instance_of(ConfigurableStateMachine::Machine).to receive(:flag_for_clearance!)
          service.call
        end

        it "returns :already_flagged if already taken on by the same team" do
          service.call
          expect(service.call).to eq :already_flagged
        end

        it "adds a transition record for private office assignment" do
          service.call
          tx = assigned_case.transitions.third
          expect(tx.event).to eq "take_on_for_approval"
          expect(tx.to_state).to eq "awaiting_responder"
          expect(tx.message).to be_nil
          expect(tx.acting_user_id).to eq private_officer.id
          expect(tx.acting_team_id).to eq private_office.id
        end

        it "triggers 2 events (1 for press, 1 for disclosure) on the state machine" do
          expect_any_instance_of(ConfigurableStateMachine::Machine).to receive(:take_on_for_approval!).exactly(2)
          service.call
        end
      end

      context "case is already taken on by DACU Disclosure" do
        before do
          allow(assigned_flagged_case.state_machine)
            .to receive(:flag_for_clearance!)
        end

        let(:service) do
          described_class.new user: private_officer,
                              kase: assigned_flagged_case,
                              team: private_office
        end

        it "returns ok when successful" do
          expect(service.call).to eq :ok
        end

        it "adds an accepted assignment for private office and private officer" do
          service.call
          expect(assigned_flagged_case
                   .approver_assignments
                   .for_team(private_office)
                   .count).to eq 1
        end

        it "does not add an assignment for DACU disclosure" do
          service.call
          expect(assigned_flagged_case
                   .approver_assignments
                   .for_team(dacu_disclosure)
                   .count).to eq 1
        end
      end
    end
  end
end
