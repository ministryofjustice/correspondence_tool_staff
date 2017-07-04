require 'rails_helper'

describe CaseFlagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) { create :assigned_case, :flagged,
                                       approving_team: dacu_disclosure }
  let(:approver)        { dacu_disclosure.approvers.first }
  let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:press_office)  { find_or_create :team_press_office }
  let(:press_officer) { create :press_officer }

  describe 'call' do
    context 'flagging by dacu disclosure' do
      context 'case is already flagged' do
        let(:service) { described_class.new user: approver,
                                            kase: assigned_flagged_case,
                                            team: dacu_disclosure }

        it 'validates whether the case is not flagged' do
          expect(service.call).to eq :already_flagged
          expect(service.result).to eq :already_flagged
        end
      end

      context 'case is not flagged already' do
        let(:service) { described_class.new user: approver,
                                            kase: assigned_case,
                                            team: dacu_disclosure }

        before do
          allow(assigned_case.state_machine).to receive(:flag_for_clearance!)
        end

        it 'triggers an event on the case state machine' do
          service.call
          expect(assigned_case.state_machine)
            .to have_received :flag_for_clearance!
        end

        it 'assigns DACU disclosure as the approving team to the case' do
          service.call
          expect(assigned_case.approving_teams).to include dacu_disclosure
        end

        it 'sets the result to ok and returns true' do
          expect(service.call).to eq :ok
          expect(service.result).to eq :ok
        end
      end
    end

    context 'flagging for press office' do
      context 'case is not already taken on by press office' do
        before do
          allow(assigned_flagged_case.state_machine).to receive(:flag_for_clearance!)
        end

        let(:service) { described_class.new user: press_officer,
                                            kase: assigned_flagged_case,
                                            team: press_office }

        it 'returns ok when successful' do
          expect(service.call).to eq :ok
        end

        it 'adds an accepted assignment for press office and press officer' do
          service.call
          assignment = assigned_flagged_case.approver_assignments
                         .for_team(press_office).first
          expect(assignment.state).to eq 'accepted'
          expect(assignment.user_id).to eq press_officer.id
          expect(assignment.approved?).to be false
        end

        it 'adds a pending assignment for DACU disclosure' do
          service.call
          assignment = assigned_flagged_case.approver_assignments
                         .for_team(dacu_disclosure).first
          expect(assignment.state).to eq 'pending'
          expect(assignment.user_id).to be_nil
          expect(assignment.approved?).to be false
        end

        it 'triggers a flag_for_clearance event on the case state machine' do
          service.call
          expect(assigned_flagged_case.state_machine)
            .to have_received :flag_for_clearance!
        end

        it 'returns :already_flagged if already taken on by the same team' do
          service.call
          expect(service.call).to eq :already_flagged
        end

        it 'adds a transition record for press office assignment' do
          service.call
          tx = assigned_flagged_case.transitions.second
          expect(tx.event).to eq 'take_on_for_approval'
          expect(tx.to_state).to eq 'awaiting_responder'
          expect(tx.message).to be_nil
          expect(tx.user_id).to eq press_officer.id
          expect(tx.approving_team_id).to eq press_office.id
        end

        it 'triggers an event on the state machine' do
          expect_any_instance_of(CaseStateMachine).to receive(:take_on_for_approval!)
          service.call
        end
      end
    end
  end

end
