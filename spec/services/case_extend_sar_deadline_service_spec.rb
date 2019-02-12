require "rails_helper"

describe CaseExtendSARDeadlineService do
  let(:team_dacu)           { find_or_create :team_disclosure_bmt }
  let(:manager)             { find_or_create :disclosure_bmt_user }
  let!(:sar_case)           { create(:approved_sar) }
  let!(:original_deadline)  { sar_case.initial_deadline }
  let!(:max_extension)      { Settings.sar_extension_limit.to_i }

  before do
    allow(sar_case.state_machine).to receive(:extend_sar_deadline!)
  end

  describe '#call' do
    context 'with expected params' do
      subject! {
        new_service(
          manager,
          sar_case,
          3,
          reason: 'test'
        ).call
      }

      it { is_expected.to eq :ok }
      it 'creates new SAR extension transition' do
        expect(sar_case.state_machine)
          .to have_received(:extend_sar_deadline!)
          .with(
            acting_user: manager,
            acting_team: team_dacu,
            final_deadline: original_deadline + 3.days,
            original_final_deadline: original_deadline,
            message: "test\nDeadline extended by 3 days"
          )
      end

      it 'sets new SAR deadline date' do
        expect(sar_case.external_deadline).to eq original_deadline + 3.days
      end
    end

    context 'validate' do
      context 'extension period' do
        context 'is missing' do
          subject! { new_service(manager, sar_case, nil).call }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be blank"]
          }
        end

        context 'is past statutory SAR extension limit' do
          let!(:extension_period) { max_extension + 5 }
          subject! {
            new_service(
              manager,
              sar_case,
              extension_period
            ).call
          }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be more than 60 days beyond the initial deadline"]
          }
        end

        context 'is before the final deadline' do
          subject! { new_service(manager, sar_case, -1).call }

          it { is_expected.to eq :validation_error }
          it {
            expect(sar_case.errors[:extension_period])
              .to eq ["can't be before the final deadline"]
          }
        end

        context 'is within limit' do
          subject! { new_service(manager, sar_case, max_extension).call }

          it { is_expected.to eq :ok }
        end
      end

      context 'reason' do
        subject! { new_service(manager, sar_case, 1, reason: '').call }

        it { is_expected.to eq :validation_error }
        it {
          expect(sar_case.errors[:reason_for_extending])
            .to eq ["can't be blank"]
        }
      end

      context 'exception' do
        let(:service) { new_service(manager, sar_case, 3) }

        it 'rolls-back changes' do
          allow(sar_case).to receive(:update!).and_throw(RuntimeError)

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

  context '#new_extension_deadline' do
    context 'calculates extended date with calendar days' do
      it 'uses the original date before first extension' do
        service = new_service(manager, sar_case, 3)

        expect(service.send(:new_extension_deadline, 3))
          .to eq(original_deadline + 3.days)

        service.call # required to create new deadline
        expect(service.result).to eq :ok
      end

      it 'uses the new extended date after first extension' do
        service = new_service(manager, sar_case, 10)
        service.call
        new_deadline = service.send(:new_extension_deadline, 10)

        expect(new_deadline).to eq(sar_case.external_deadline + 10.days)
        expect(new_deadline).not_to eq original_deadline
      end
    end
  end

  private

  def new_service(user, kase, extension_period, reason: 'Testing')
    CaseExtendSARDeadlineService.new(
      user,
      kase,
      extension_period,
      reason
    )
  end
end
