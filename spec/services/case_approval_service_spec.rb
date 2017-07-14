require 'rails_helper'

describe CaseApprovalService do

  describe '#call' do

    let(:service)  { CaseApprovalService.new(user: user, kase: kase) }

    context 'case not in pending_dacu_clearance state' do

      let(:kase) { create :accepted_case, :flagged_accepted }
      let(:user) { kase.approvers.first }

      it 'raises state machine guard error' do
        expect(kase.current_state).to eq 'drafting'
        expect { service.call }
          .to raise_error(Statesman::TransitionFailedError)
      end
    end

    context 'approving case with valid state and user' do
      let(:kase) { create :pending_dacu_clearance_case }
      let(:user) { kase.approvers.first }

      it 'returns :ok' do
        service.call
        expect(service.result).to eq :ok
      end

      it 'sets the assignment approved flag' do
        expect(kase.approver_assignments.first.approved?).to be false
        service.call
        expect(kase.approver_assignments.first.approved?).to be true
      end

      it 'sets the state to awaiting_dispatch' do
        expect(kase.current_state).to eq 'pending_dacu_clearance'
        service.call
        expect(kase.current_state).to eq 'awaiting_dispatch'
      end

      it 'adds a case_transition record' do
        expect {
          service.call
        }.to change { kase.transitions.size }.by(1)
        transition = kase.transitions.last
        expect(transition.event).to eq 'approve'
        expect(transition.user_id).to eq user.id
        expect(transition.approving_team_id).to eq kase.approving_teams.first.id
      end
    end

    context 'escalating case' do
      let(:kase)                 { create :pending_dacu_clearance_case, :press_office, approver: user }
      let(:user)                 { create :disclosure_specialist }
      let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }

      it 'returns :ok' do
        service.call
        expect(service.result).to eq :ok
      end

      it 'sets the assignment approved flag' do
        expect(kase.approver_assignments.with_teams(team_dacu_disclosure).first.approved?).to be false
        service.call
        expect(kase.approver_assignments.with_teams(team_dacu_disclosure).first.approved?).to be true
      end

      it 'sets the state to awaiting_dispatch' do
        expect(kase.current_state).to eq 'pending_dacu_clearance'
        service.call
        expect(kase.current_state).to eq 'pending_press_office_clearance'
      end

      it 'adds a case_transition record' do
        expect {
          service.call
        }.to change { kase.transitions.size }.by(1)
        transition = kase.transitions.last
        expect(transition.event).to eq 'escalate_to_press_office'
        expect(transition.user_id).to eq user.id
        expect(transition.approving_team_id).to eq kase.approving_teams.first.id
      end
    end

    context 'approving case with different user in the same team' do
      let(:kase) { create :pending_dacu_clearance_case }
      let(:user) { create :approver,
                          approving_team: kase.approving_teams.first }

      it 'returns :ok' do
        service.call
        expect(service.result).to eq :ok
      end

      it 'adds a case_transition record' do
        expect {
          service.call
        }.to change { kase.transitions.size }.by(1)
        transition = kase.transitions.last
        expect(transition.event).to eq 'approve'
        expect(transition.user_id).to eq user.id
        expect(transition.approving_team_id).to eq kase.approving_teams.first.id
      end
    end
  end
end
