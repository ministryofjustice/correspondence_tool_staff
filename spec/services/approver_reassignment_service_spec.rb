require 'rails_helper'

describe ApproverReassignmentService do


  describe '#call' do

    let(:kase) { find_or_create :pending_dacu_clearance_case }
    let(:disclosure_specialist) { create :disclosure_specialist }
    let(:service) { ApproverReassignmentService.new(user: disclosure_specialist,
                                                    kase: kase) }
    let(:policy) { service.instance_variable_get(:@policy) }

    context 'unauthorised' do

      before(:each) { allow(policy).to receive(:can_reassign_approver?).and_return(false) }

      it 'returns :unauthorised' do
        expect(service.call).to eq :unauthorised
      end

      it 'does not create a transition record' do
        expect {
          service.call
        }.not_to change{ kase.transitions.count }
      end

      it 'does not update the approver assignment record' do
        assignment = kase.approver_assignments.first
        service.call
        expect(kase.approver_assignments).to include assignment
      end
    end

    context 'authorised' do
      it 'returns :ok' do
        expect(service.call).to eq :ok
      end

      it 'creates a transition record' do
        expect {
          service.call
        }.to change{ kase.transitions.count }.by(1)

      end

      it 'updates the assignment record' do
        assignment = kase.approver_assignments.first
        service.call
        expect(kase.approver_assignments).to include assignment
      end

    end
  end
end
