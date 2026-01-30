require "rails_helper"

describe CaseExtendSARDeadlineService do
  shared_examples "SAR Extension Service" do
    let!(:initial_deadline) { kase.initial_deadline }
    let!(:max_extension_time_limit) { kase.correspondence_type.extension_time_limit }

    before do
      allow(kase.state_machine).to receive(:extend_sar_deadline!)
    end

    describe "#call" do
      context "with expected params" do
        subject!(:extension_service_result) do
          sar_extension_service(
            user: manager,
            kase: kase,
            extension_period: 1,
            reason: "test",
          ).call
        end

        it { expect(extension_service_result).to eq :ok }

        it "creates new SAR extension transition" do
          expect(kase.state_machine)
            .to have_received(:extend_sar_deadline!)
            .with(
              acting_user: manager,
              acting_team: acting_team,
              final_deadline: get_expected_deadline(2.months.since(kase.received_date)),
              original_final_deadline: initial_deadline,
              message: "test\nDeadline extended by one calendar month",
            )
        end

        it "sets new SAR deadline date" do
          expect(kase.external_deadline).to eq get_expected_deadline(2.months.since(kase.received_date))
        end
      end

      context "when after initial deadline" do
        it "allows retrospective extension" do
          deadline = kase.initial_deadline

          Timecop.travel(deadline + 100.days) do
            result = sar_extension_service(
              user: manager,
              kase: kase,
              extension_period: max_extension_time_limit,
            ).call

            expect(result).to eq :ok
            expect(kase.external_deadline)
              .to eq get_expected_deadline((max_extension_time_limit + 1).month.since(kase.received_date))
            expect(kase.external_deadline).to be < Time.zone.now
          end
        end
      end
    end

    describe "validate" do
      context "with extension period" do
        context "when it is missing" do
          subject!(:extension_service_result) do
            sar_extension_service(
              user: manager,
              kase: kase,
              extension_period: nil,
            ).call
          end

          it { is_expected.to eq :validation_error }

          it "has error message" do
            expect(kase.errors[:extension_period]).to eq ["cannot be blank"]
          end
        end

        context "when it is past statutory SAR extension limit" do
          subject!(:extension_service_result) do
            sar_extension_service(
              user: manager,
              kase: kase,
              extension_period: max_extension_time_limit + 1,
            ).call
          end

          it { is_expected.to eq :validation_error }

          it "has error message" do
            expect(kase.errors[:extension_period]).to eq ["cannot be more than two calendar months beyond the received date"]
          end
        end

        context "when it is before the final deadline" do
          subject!(:extension_service_result) do
            sar_extension_service(
              user: manager,
              kase: kase,
              extension_period: -1,
            ).call
          end

          it { is_expected.to eq :validation_error }

          it "has error message" do
            expect(kase.errors[:extension_period]).to eq ["cannot be before the final deadline"]
          end
        end

        context "when it is within limit" do
          subject!(:extension_service_result) do
            sar_extension_service(
              user: manager,
              kase: kase,
              extension_period: max_extension_time_limit,
            ).call
          end

          it { is_expected.to eq :ok }
        end
      end

      context "with reason" do
        subject!(:extension_service_result) do
          sar_extension_service(
            user: manager,
            kase: kase,
            extension_period: 1,
            reason: "",
          ).call
        end

        it { is_expected.to eq :validation_error }

        it "has error message" do
          expect(kase.errors[:reason_for_extending]).to eq ["cannot be blank"]
        end
      end

      # Force #call transaction block to fail, can be any kind of StandardError
      context "when on any transaction exception" do
        before do
          allow(kase).to receive(:update!).and_throw(StandardError)
        end

        let!(:service) do
          sar_extension_service(
            user: manager,
            kase: kase,
            extension_period: 1,
          )
        end

        it "does not transition SAR state" do
          service.call
          transitions = kase.transitions.where(event: "extend_sar_deadline")

          expect(transitions.any?).to be false
        end

        it "sets result to :error and returns :error" do
          result = service.call

          expect(result).to eq :error
          expect(service.result).to eq :error
        end
      end
    end

    def sar_extension_service(user:, kase:, extension_period:, reason: "Testing")
      CaseExtendSARDeadlineService.new(
        user:,
        kase:,
        extension_period:,
        reason:,
      )
    end
  end

  # rubocop:disable RSpec/LetSetup
  describe "Standard SAR case" do
    let!(:acting_team)  { find_or_create :team_disclosure_bmt }
    let!(:manager)      { find_or_create :disclosure_bmt_user }
    let!(:kase)         { freeze_time { create(:approved_sar) } }

    it "is a Standard SAR case" do
      expect(kase).to be_a(Case::SAR::Standard)
    end

    include_examples "SAR Extension Service"
  end

  describe "Offender SAR case" do
    let!(:acting_team)  { find_or_create :team_disclosure_bmt }
    let!(:manager)      { find_or_create :disclosure_bmt_user }
    let!(:kase)         { freeze_time { create(:offender_sar_case, :ready_for_vetting) } }

    it "is a Standard SAR case" do
      expect(kase).to be_a(Case::SAR::Offender)
    end

    include_examples "SAR Extension Service"
  end
  # rubocop:enable RSpec/LetSetup
end
