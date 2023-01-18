require "rails_helper"

describe CaseFilter::CaseUpdateSentToSsclService do
  let(:kase) { create :offender_sar_case, :closed }
  let(:user) { kase.responding_team.users.first }
  let(:team) { kase.responding_team }
  let(:state_machine) { double ConfigurableStateMachine::Machine, record_sent_to_sscl!: true }
  let(:params) { { sent_to_sscl_at: Date.current - 1.day } }
  let(:service) { CaseUpdateSentToSsclService.new(user: user, kase: kase, params: params) }

  before(:each) do
    allow(kase).to receive(:state_machine).and_return(state_machine)
    allow(state_machine).to receive(:record_sent_to_sscl!).with(
      acting_user: user,
      acting_team: team
    )
  end

  describe 'update case' do
    context 'case has not been sent to SSCL' do
      it 'records as sent to SSCL' do
        service.call
        expect(state_machine).to have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team
        )
        expect(service.result).to eq :ok
      end
    end

    context 'no change made' do
      let(:params) { { } }

      it 'does not record as sent to SSCL' do
        service.call
        expect(state_machine).to_not have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team
        )
        expect(service.result).to eq :no_changes
      end
    end

    context 'invalid change made' do
      let(:params) { { sent_to_sscl_at: Date.current + 100.years} }

      it 'does not record as sent to SSCL' do
        service.call
        expect(state_machine).to_not have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team
        )
        expect(service.result).to eq :error
        expect(service.message).to be_present
      end
    end

    context 'case has already been sent to SSCL' do
      before { kase.update_attribute(:sent_to_sscl_at, Date.current) }

      it 'does not record as sent to SSCL' do
        service.call
        expect(state_machine).to_not have_received(:record_sent_to_sscl!).with(
          acting_user: user,
          acting_team: team
        )
        expect(service.result).to eq :ok
      end
    end
  end
end
