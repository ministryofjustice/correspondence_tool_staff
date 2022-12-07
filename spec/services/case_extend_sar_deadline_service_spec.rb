require "rails_helper"

describe CaseExtendSARDeadlineService do
  let!(:team_disclosure_bmt) { find_or_create :team_disclosure_bmt }
  let!(:manager)             { find_or_create :disclosure_bmt_user }
  let!(:sar_case)            { freeze_time { create(:approved_sar) } }
  let!(:initial_deadline)    { sar_case.initial_deadline }
  let!(:max_extension_time_limit)  { sar_case.correspondence_type.extension_time_limit }

  before do
    allow(sar_case.state_machine).to receive(:extend_sar_deadline!)
  end

  describe '#call' do
    context 'with expected params' do
      let!(:extension_service_result) {
        sar_extension_service(
          user: manager,
          kase: sar_case,
          extension_period: 1,
          reason: 'test'
        ).call
      }

      it { expect(extension_service_result).to eq :ok }

      it 'creates new SAR extension transition' do
        expect(sar_case.state_machine)
          .to have_received(:extend_sar_deadline!)
          .with(
            acting_user: manager,
            acting_team: team_disclosure_bmt,
            final_deadline: get_expected_deadline(2.month.since(sar_case.received_date)),
            original_final_deadline: initial_deadline,
            message: "test\nDeadline extended by one calendar month"
          )
      end

      it 'sets new SAR deadline date' do
        expect(sar_case.external_deadline).to eq get_expected_deadline(2.month.since(sar_case.received_date))
      end
    end

    context 'after initial deadline' do
      it 'allows retrospective extension' do
        deadline = sar_case.initial_deadline

        Timecop.travel(deadline + 100.days) do
          result = sar_extension_service(
            user: manager,
            kase: sar_case,
            extension_period: max_extension_time_limit
          ).call

          expect(result).to eq :ok
          expect(sar_case.external_deadline)
            .to eq get_expected_deadline((max_extension_time_limit+1).month.since(sar_case.received_date))
          expect(sar_case.external_deadline).to be < DateTime.now
        end
      end
    end

    context 'validate' do
      context 'extension period' do
        context 'is missing' do
          let!(:extension_service_result) {
            sar_extension_service(
              user: manager,
              kase: sar_case,
              extension_period: nil
            ).call
          }

          it {
            expect(extension_service_result)
              .to eq :validation_error
          }

          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["cannot be blank"]
          }
        end

        context 'is past statutory SAR extension limit' do
          let(:extension_period) { max_extension_time_limit + 1 }
          let!(:extension_service_result) {
            sar_extension_service(
              user: manager,
              kase: sar_case,
              extension_period: extension_period
            ).call
          }

          it {
            expect(extension_service_result)
              .to eq :validation_error
          }

          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["cannot be more than two calendar months beyond the received date"]
          }
        end

        context 'is before the final deadline' do
          let!(:extension_service_result) {
            sar_extension_service(
              user: manager,
              kase: sar_case,
              extension_period: -1
            ).call
          }

          it {
            expect(extension_service_result)
              .to eq :validation_error
          }

          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["cannot be before the final deadline"]
          }
        end

        context 'is within limit' do
          let!(:extension_service_result) {
            sar_extension_service(
              user: manager,
              kase: sar_case,
              extension_period: max_extension_time_limit
            ).call
          }

          it {
            expect(extension_service_result)
              .to eq :ok
          }
        end
      end

      context 'reason' do
        let!(:extension_service_result) {
          sar_extension_service(
            user: manager,
            kase: sar_case,
            extension_period: 1,
            reason: ''
          ).call
        }

        it {
          expect(extension_service_result)
            .to eq :validation_error
        }

        it {
          expect(sar_case.errors[:reason_for_extending])
            .to eq ["cannot be blank"]
        }
      end

      # Force #call transaction block to fail, can be any kind of StandardError
      context 'on any transaction exception' do
        let!(:service) {
          sar_extension_service(
            user: manager,
            kase: sar_case,
            extension_period: 1
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

  def sar_extension_service(user:, kase:, extension_period:, reason: 'Testing')
    CaseExtendSARDeadlineService.new(
      user: user,
      kase: kase,
      extension_period: extension_period,
      reason: reason
    )
  end
end
