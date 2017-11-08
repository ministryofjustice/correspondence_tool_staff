require "rails_helper"

describe CaseExtendForPITService do
  let(:case_being_drafted) { create :case_being_drafted }
  let(:manager) { find_or_create :disclosure_bmt_user }

  let(:service) { CaseExtendForPITService.new manager,
                                              case_being_drafted,
                                              10.business_days.after(Date.today),
                                              'I lkie to extend my best tests' }

  describe '#call' do
    before do
      allow(case_being_drafted.state_machine).to receive(:extend_for_pit!)
    end

    it 'calls extend_for_pit on the case state machine' do
      service.call
      expect(case_being_drafted.state_machine)
        .to have_received(:extend_for_pit!)
              .with manager,
                    10.business_days.after(Date.today),
                    'I lkie to extend my best tests'
    end

    it 'sets the external deadline on the case' do
      service.call
      expect(case_being_drafted.external_deadline)
        .to eq 10.business_days.after(Date.today)
    end

    it 'sets result to :ok and returns same' do
      result = service.call
      expect(result).to eq :ok
      expect(service.result).to eq :ok
    end

    context 'when an error occurs' do
      it 'rolls-back changes' do
        allow(case_being_drafted).to receive(:update!).and_throw(RuntimeError)
        service.call
        extend_for_pit_transitions = case_being_drafted.transitions.where(
          event: 'extend_for_pit'
        )
        expect(extend_for_pit_transitions.any?).to be false
      end

      it 'sets result to :error and returns same' do
        allow(case_being_drafted).to receive(:update!).and_throw(RuntimeError)
        result = service.call
        expect(result).to eq :error
        expect(service.result).to eq :error
      end
    end
  end

end
