require 'rails_helper'

describe CaseUnflagForClearanceService do
  let(:assigned_case)         { create :assigned_case }
  let(:assigned_flagged_case) { create :assigned_case,
                                       :flagged_accepted,
                                       :dacu_disclosure }
  let(:approver)              { dacu_disclosure.approvers.first }
  let(:team_dacu)             { find_or_create :team_dacu }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:press_office)          { find_or_create :team_press_office }

  describe 'call' do
    context 'case is not already flagged' do
      let(:service) { described_class.new user: approver,
                                          kase: assigned_case,
                                          team: dacu_disclosure }

      it 'validates that the case is flagged' do
        expect(service.call).to eq :not_flagged
        expect(service.result).to eq :not_flagged
      end
    end

    context 'case is flagged' do
      let(:service) { described_class.new user: approver,
                                          kase: assigned_flagged_case,
                                          team: dacu_disclosure }

      before do
        allow(assigned_flagged_case.state_machine)
          .to receive(:unflag_for_clearance!)
      end

      it 'triggers an event on the case state machine' do
        service.call
        expect(assigned_flagged_case.state_machine)
          .to have_received(:unflag_for_clearance!)
                .with(approver, team_dacu, dacu_disclosure)
      end

      it 'removes the approving team assignment' do
        service.call
        expect(assigned_flagged_case.approving_teams).to be_blank
      end

      it 'sets the result to ok and returns true' do
        expect(service.call).to eq :ok
        expect(service.result).to eq :ok
      end
    end
  end
end
