require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R007ClosedCasesReport do
    before(:all) { create_report_type(abbr: :r007) }

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Closed cases report"
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Entire list of closed cases"
      end
    end

    describe ".etl_handler" do
      it "returns correct etl_handler" do
        expect(described_class.etl_handler)
          .to eq Stats::ETL::ClosedCases
      end
    end

    describe "reporting" do
      before(:all) do
        @period_start = Date.new(2018, 12, 20)
        @period_end = Date.new(2018, 12, 31)
        @user = create :manager

        @cases = {
          closed_sar: {
            type: :closed_sar,
            received: @period_end - 1.hour,
          },
          closed_foi: {
            type: :closed_case,
            received: @period_start,
          },
          outside_period_foi: {
            type: :closed_case,
            received: @period_end + 1.day,
          },
          responded_foi: {
            type: :responded_case,
            received: @period_start + 1.hour,
          },
          open_foi: {
            type: :accepted_case,
            received: @period_start + 1.day,
            state: "totally-not-accepted-really",
          },
        }

        @cases.each do |key, options|
          kase = build(
            options[:type],
            name: key,
            received_date: options[:received],
            current_state: options[:state] || "closed",
          )

          kase.save!(validate: false)
          @cases[key][:case] = kase
        end

        @report = described_class.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end,
        )
      end

      describe "#case_scope" do
        it "ignores any selected periods" do
          expected = %w[closed_sar closed_foi outside_period_foi responded_foi]
          expect(@report.case_scope.map(&:name)).to match_array(expected)
        end
      end

      describe "#run" do
        it "creates a job to generate closed cases" do
          expect {
            @report.run(report_guid: SecureRandom.uuid)
          }.to change {
            ActiveJob::Base.queue_adapter.enqueued_jobs.count
          }.by 1
        end
      end

      describe "#report_details" do
        let(:redis) { double("redis") } # rubocop:disable RSpec/VerifiedDoubles
        let(:report) { create(:report) }
        let(:data) { "some data" }

        before do
          allow(Sidekiq).to receive(:redis).and_yield(redis)
          allow(redis).to receive(:exists).with(report.guid).and_return(exists)
          allow(redis).to receive(:get).with(report.guid).and_return(data)
        end

        context "when data is in redis" do
          let(:exists) { 1 }

          it "sets the report as complete" do
            expect {
              @report.report_details(report)
            }.to change(report, :status).to Stats::BaseReport::COMPLETE
          end

          it "returns data stored in Redis" do
            expect(@report.report_details(report)).to eq data
          end
        end

        context "when data is not in redis" do
          let(:exists) { 0 }

          it "doesn't change the report status" do
            expect {
              @report.report_details(report)
            }.not_to change(report, :status)
          end

          it "returns nil" do
            expect(@report.report_details(report)).to be_nil
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
