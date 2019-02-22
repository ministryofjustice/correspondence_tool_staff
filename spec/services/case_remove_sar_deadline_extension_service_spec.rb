require "rails_helper"

describe CaseRemoveSARDeadlineExtensionService do
  let(:team_dacu)         { find_or_create :team_disclosure_bmt }
  let(:manager)           { find_or_create :disclosure_bmt_user }
  let(:sar_case)          { create(:sar_case, :extended_deadline_sar) }
  let(:initial_deadline)  { sar_case.initial_deadline }
  let(:max_extension)     { Settings.sar_extension_limit.to_i }

  before do
    allow(sar_case.state_machine).to receive(:remove_sar_deadline_extension!)
  end

  describe '#initialize' do
    let(:sar_extension_remove_service) {
      remove_sar_extension_service(manager, sar_case)
    }

    it { expect(sar_case.external_deadline).not_to eq initial_deadline }
    it { expect(sar_extension_remove_service.result).to eq :incomplete }
  end

  describe '#call' do
    context 'with expected params' do
      let!(:sar_extension_remove_service_result) {
        remove_sar_extension_service(manager, sar_case).call
      }

      it { expect(sar_extension_remove_service_result).to eq :ok }

      it 'creates new SAR extension removal transition' do
        expect(sar_case.state_machine)
          .to have_received(:remove_sar_deadline_extension!)
          .with(
            acting_user: manager,
            acting_team: team_dacu
          )
      end

      it 'resets SAR deadline date' do
        expect(sar_case.external_deadline).to eq initial_deadline
      end
    end

    context 'after initial deadline' do
      it 'allows retrospective removal' do
        expect(sar_case.external_deadline).to be > sar_case.initial_deadline
        expect(sar_case.deadline_extended?).to be true

        Timecop.travel(sar_case.external_deadline + 100.days) do
          result = remove_sar_extension_service(manager, sar_case).call

          expect(result).to eq :ok
          expect(sar_case.external_deadline).to eq initial_deadline
          expect(sar_case.deadline_extended?).to be false
        end
      end
    end

    # Force #call transaction block to fail, can be any kind of StandardError
    context 'on any transaction exception' do
      let(:service) {
        remove_sar_extension_service(
          manager,
          sar_case
        )
      }

      it 'does not transition SAR state' do
        allow(sar_case).to receive(:reset_deadline!).and_throw(ArgumentError)

        expect { service.call }.to raise_error(ArgumentError)
        expect(service.result).to eq :error

        transitions = sar_case.transitions.where(
          event: 'remove_sar_deadline_extension'
        )

        expect(transitions.any?).to be false
      end
    end
  end

  private

  def remove_sar_extension_service(user, kase)
    CaseRemoveSARDeadlineExtensionService.new(
      user,
      kase
    )
  end
end
