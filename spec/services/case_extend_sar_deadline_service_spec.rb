require "rails_helper"

describe CaseExtendSARDeadlineService do
  let(:team_disclosure_bmt) { find_or_create :team_disclosure_bmt }
  let(:manager)             { find_or_create :disclosure_bmt_user }
  let!(:sar_case)           { create(:approved_sar) }
  let!(:initial_deadline)   { sar_case.initial_deadline }
  let!(:max_extension)      { Settings.sar_extension_limit.to_i }

  before do
    allow(sar_case.state_machine).to receive(:extend_sar_deadline!)
  end

  describe '#call' do
    context 'with expected params' do
      subject!(:extension_service) {
        sar_extension_service(
          manager,
          sar_case,
          extension_period: 3,
          reason: 'test'
        ).call
      }

      it { is_expected.to eq :ok }
      it 'creates new SAR extension transition' do
        expect(sar_case.state_machine)
          .to have_received(:extend_sar_deadline!)
          .with(
            acting_user: manager,
            acting_team: team_disclosure_bmt,
            final_deadline: initial_deadline + 3.days,
            original_final_deadline: initial_deadline,
            message: "test\nDeadline extended by 3 days"
          )
      end

      it 'sets new SAR deadline date' do
        expect(sar_case.external_deadline).to eq initial_deadline + 3.days
      end
    end

    context 'after initial deadline' do
      it 'allows retrospective extension' do
        deadline = sar_case.initial_deadline

        Timecop.travel(deadline + 100.days) do
          result = sar_extension_service(
            manager,
            sar_case,
            extension_period: max_extension
          ).call

          expect(result).to eq :ok
          expect(sar_case.external_deadline).to eq deadline + max_extension.days
          expect(sar_case.external_deadline).to be < DateTime.now
        end
      end
    end

    context 'validate' do
      context 'extension period' do
        context 'is missing' do
          subject!(:extension_service) {
            sar_extension_service(
              manager,
              sar_case,
              extension_period: nil
            ).call
          }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be blank"]
          }
        end

        context 'is past statutory SAR extension limit' do
          let!(:extension_period) { max_extension + 5 }
          subject!(:extension_service) {
            sar_extension_service(
              manager,
              sar_case,
              extension_period: extension_period
            ).call
          }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be more than 60 days beyond the initial deadline"]
          }
        end

        context 'is before the final deadline' do
          subject!(:extension_service) {
            sar_extension_service(
              manager,
              sar_case,
              extension_period: -1
            ).call
          }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be before the final deadline"]
          }
        end

        context 'is within limit' do
          subject!(:extension_service) {
            sar_extension_service(
              manager,
              sar_case,
              extension_period: max_extension
            ).call
          }

          it { is_expected.to eq :ok }
        end
      end

      context 'reason' do
        subject!(:extension_service) {
          sar_extension_service(
            manager,
            sar_case,
            extension_period: 1,
            reason: ''
          ).call
        }

        it { is_expected.to eq :validation_error }
        it {
          expect(sar_case.errors[:reason_for_extending])
            .to eq ["can't be blank"]
        }
      end

      # Force #call transaction block to fail, can be any kind of StandardError
      context 'on any transaction exception' do
        let(:service) {
          sar_extension_service(
            manager,
            sar_case,
            extension_period: 3
          )
        }

        it 'does not transition SAR state' do
          allow(sar_case).to receive(:update!).and_throw(StandardError)

          service.call
          transitions = sar_case.transitions.where(
            event: 'extend_sar_deadline'
          )

          expect(transitions.any?).to be false
        end

        it 'sets result to :error and returns :error' do
          allow(sar_case).to receive(:update!).and_throw(RuntimeError)

          result = service.call

          expect(result).to eq :error
          expect(service.result).to eq :error
        end
      end
    end
  end

  private

  def sar_extension_service(user, kase, extension_period:, reason: 'Testing')
    CaseExtendSARDeadlineService.new(
      user,
      kase,
      extension_period,
      reason
    )
  end
end
