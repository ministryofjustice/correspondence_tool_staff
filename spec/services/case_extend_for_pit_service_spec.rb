require "rails_helper"

describe CaseExtendForPITService do
  let(:case_being_drafted) { create :case_being_drafted }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:old_external_deadline) { case_being_drafted.external_deadline }
  let(:days_to_extend_deadline_by) { 10 }
  let(:new_external_deadline) { days_to_extend_deadline_by
                                  .business_days
                                  .after(old_external_deadline) }
  let(:service) { CaseExtendForPITService.new(
                    manager,
                    case_being_drafted,
                    new_external_deadline,
                    'I like to extend my best tests'
                  ) }

  describe '#call' do
    before do
      allow(case_being_drafted.state_machine).to receive(:extend_for_pit!)
    end

    it 'calls extend_for_pit on the case state machine' do
      service.call
      expect(case_being_drafted.state_machine)
        .to have_received(:extend_for_pit!)
        .with(acting_user: manager,
              acting_team: team_dacu_disclosure,
              final_deadline: 10.business_days.after(old_external_deadline),
              message: 'I like to extend my best tests')
    end

    it 'sets the external deadline on the case' do
      service.call
      expect(case_being_drafted.external_deadline)
        .to eq 10.business_days.after(old_external_deadline)
    end

    it 'sets result to :ok and returns same' do
      result = service.call
      expect(result).to eq :ok
      expect(service.result).to eq :ok
    end

    context 'when the reason for extending is missing' do
      let(:service) { CaseExtendForPITService.new(
                        manager,
                        case_being_drafted,
                        10.business_days.after(Date.today),
                        ''
                      ) }

      it 'sets the result to :validation_error and returns it' do
        result = service.call
        expect(result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(case_being_drafted.errors[:reason_for_extending])
          .to eq ["can't be blank"]
      end
    end

    context 'when the extension deadline is missing' do
      let(:service) { CaseExtendForPITService.new(
                        manager,
                        case_being_drafted,
                        nil,
                        'no deadline'
                      ) }

      it 'sets the result to :validation_error and returns it' do
        result = service.call
        expect(result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(case_being_drafted.errors[:extension_deadline])
          .to eq ["Date can't be blank"]
      end
    end

    context 'when the extension deadline is too far in the future' do
      let(:days_to_extend_deadline_by) { Settings.pit_extension_limit.to_i + 1 }

      it 'sets the result to :validation_error and returns it' do
        result = service.call
        expect(result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(case_being_drafted.errors[:extension_deadline])
          .to eq ["Date is more than 20 beyond the final deadline"]
      end
    end

    context 'when the extension deadline is before the final deadline' do
      let(:new_external_deadline) { 1.business_days.before(old_external_deadline) }

      it 'sets the result to :validation_error and returns it' do
        result = service.call
        expect(result).to eq :validation_error
      end

      it 'adds an error to the case' do
        service.call
        expect(case_being_drafted.errors[:extension_deadline])
          .to eq ["Date can't be before the final deadline"]
      end
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
