require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  class DummyPerformanceReport < BaseMonthlyPerformanceReport
    def self.title
      "Monthly Performance report"
    end

    def self.description
      "Dummy Performance Report for testing."
    end

    def report_type
      ReportType.first
    end

    def case_scope
      Case::Base.all
    end
  end

  describe BaseMonthlyPerformanceReport do
    before(:all) { create_report_type(abbr: "dummy") }

    after(:all) do
      DbHousekeeping.clean(seed: true)
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
          outside_period_sar: {
            type: :closed_sar,
            received: @period_end + 1.day,
          },
          responded_sar: {
            type: :closed_sar,
            received: @period_start + 1.hour,
          },
          open_sar: {
            type: :accepted_sar,
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

        @report = DummyPerformanceReport.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end,
        )

        @report_another = DummyPerformanceReport.new(
          user: @user,
          period_start: @period_start,
          period_end: @period_end,
        )
      end

      describe "#case_scope" do
        it "ignores any selected periods" do
          expected = %w[closed_sar closed_foi outside_period_sar responded_sar open_sar]
          expect(@report.case_scope.map(&:name)).to match_array(expected)
        end
      end

      describe "#run" do
        it "generate the report without creating the job" do
          stub_const("Stats::ROWS_PER_FRAGMENT", 2)
          allow(@report).to receive(:analyse_case)
          @report.run(report_guid: SecureRandom.uuid)
          expect(@report).to have_received(:analyse_case).at_least(4).times

          expect(@report.background_job).to eq false
          expect(@report.status).to eq Stats::BaseReport::COMPLETE
          expect(@report.persist_results?).to eq true
          expect(@report.num_fragments).to eq 2
          expect(@report.data_size).to eq 4

          expect {
            @report.run(report_guid: SecureRandom.uuid)
          }.to change {
            ActiveJob::Base.queue_adapter.enqueued_jobs.count
          }.by 0
        end

        it "creates a job to generate report" do
          stub_const("Stats::ROWS_PER_FRAGMENT", 1)
          stub_const("Stats::MAXIMUM_LIMIT_FOR_USING_JOB", 1)
          expect {
            @report_another.run(report_guid: SecureRandom.uuid)
          }.to change {
            ActiveJob::Base.queue_adapter.enqueued_jobs.count
          }.by 4

          expect(@report_another.num_fragments).to eq 4
          expect(@report_another.data_size).to eq 4
          expect(@report_another.background_job).to eq true
          expect(@report_another.status).to eq Stats::BaseReport::WAITING
          expect(@report_another.persist_results?).to eq true
        end
      end

      describe "#process" do
        it "more months compared iwth period stfrom stats data " do
          redis_double = instance_double(Redis)
          allow(Redis).to receive(:new).and_return(redis_double)

          allow(redis_double).to receive(:exists?).and_return(true)
          allow(redis_double).to receive(:get).and_return(
            '{"201811":
              {"month":0,
                "non_trigger_performance":0,
                "non_trigger_total":0,
                "non_trigger_responded_in_time":0,
                "non_trigger_responded_late":0,
                "non_trigger_open_in_time":30,
                "non_trigger_open_late":5,
                "trigger_performance":0,
                "trigger_total":0,
                "trigger_responded_in_time":0,
                "trigger_responded_late":0,
                "trigger_open_in_time":0,
                "trigger_open_late":0,
                "overall_performance":0,
                "overall_total":0,
                "overall_responded_in_time":0,
                "overall_responded_late":0,
                "overall_open_in_time":30,
                "overall_open_late":5},
              "201812":
              { "month":0,
                "non_trigger_performance":0,
                "non_trigger_total":0,
                "non_trigger_responded_in_time":0,
                "non_trigger_responded_late":0,
                "non_trigger_open_in_time":20,
                "non_trigger_open_late":10,
                "trigger_performance":0,
                "trigger_total":0,
                "trigger_open_in_time":0,
                "trigger_open_late":0,
                "trigger_responded_in_time":0,
                "trigger_responded_late":0,
                "overall_performance":0,
                "overall_total":0,
                "overall_responded_in_time":0,
                "overall_responded_late":0,
                "overall_open_in_time":20,
                "overall_open_late":10},
              "total":
              { "month":0,
                "non_trigger_performance":0,
                "non_trigger_total":0,
                "non_trigger_responded_in_time":0,
                "non_trigger_responded_late":0,
                "non_trigger_open_in_time":0,
                "non_trigger_open_late":0,
                "trigger_performance":0,
                "trigger_total":0,
                "trigger_open_in_time":0,
                "trigger_open_late":0,
                "trigger_responded_in_time":0,
                "trigger_responded_late":0,
                "overall_performance":0,
                "overall_total":0,
                "overall_responded_in_time":0,
                "overall_responded_late":0,
                "overall_open_in_time":50,
                "overall_open_late":15}}',
          )
          new_report = Report.new(
            report_type_id: find_or_create(:report_type, :r205).id,
            period_start: @period_start,
            period_end: @period_end,
          )
          new_report.job_ids = %w[job1]
          result_data = JSON.parse(@report.report_details(new_report))
          expect(result_data.key?("201812")).to eq true
          expect(result_data.key?("total")).to eq true
          expect(result_data.key?("201811")).to eq false
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
