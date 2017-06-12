require 'rails_helper'

describe CaseFlagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) { create :assigned_case, :flagged,
                                       approving_team: dacu_disclosure }
  let(:approver)        { dacu_disclosure.approvers.first }
  let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }

  describe 'call' do
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
        allow(assigned_case.state_machine)
          .to receive(:flag_for_clearance!)
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
end
