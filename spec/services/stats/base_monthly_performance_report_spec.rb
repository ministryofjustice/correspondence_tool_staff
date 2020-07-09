require 'rails_helper'

module Stats

  class DummyPerformanceReport < BaseMonthlyPerformanceReport

    def self.title
        'Monthly Performance report'
    end
  
    def self.description
        'Dummy Performance Report for testing.'
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
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe 'reporting' do
        before(:all) do
          @period_start = Date.new(2018, 12, 20)
          @period_end = Date.new(2018, 12, 31)
          @user = create :manager
  
          @cases = {
            closed_sar: {
              type: :closed_sar,
              received: @period_end - 1.hours,
            },
            closed_foi: {
              type: :closed_case,
              received: @period_start,
            },
            outside_period_sar: {
              type: :closed_sar,
              received: @period_end + 1.days
            },
            responded_sar: {
              type: :closed_sar,
              received: @period_start + 1.hour,
            },
            open_sar: {
              type: :accepted_sar,
              received: @period_start + 1.days,
              state: 'totally-not-accepted-really'
            },
          }
  
          @cases.each do |key, options|
            kase = build(
              options[:type],
              name: key,
              received_date: options[:received],
              current_state: options[:state] || 'closed'
            )
  
            kase.save(validate: false)
            @cases[key][:case] = kase
          end
  
          @report = DummyPerformanceReport.new(
            user: @user,
            period_start: @period_start,
            period_end: @period_end
          )

          @report_another = DummyPerformanceReport.new(
            user: @user,
            period_start: @period_start,
            period_end: @period_end
          )
        end
  
        context '#case_scope' do
          it 'ignores any selected periods' do
            expected = %w[closed_sar closed_foi outside_period_sar responded_sar open_sar]
            expect(@report.case_scope.map(&:name)).to match_array(expected)
          end
        end
  
        context '#run' do
            it 'generate the report without creating the job' do
                stub_const("Stats::ROWS_PER_FRAGMENT", 6)
                allow(@report).to receive(:process)
                @report.run(report_guid: SecureRandom.uuid)
                expect(@report).to have_received(:process).once               

                expect(@report.etl).to eq false
                expect(@report.status).to eq Stats::BaseReport::COMPLETE
                expect(@report.persist_results?).to eq true
                expect(@report.num_fragments).to eq 1
                expect(@report.data_size).to eq 4

                expect {
                @report.run(report_guid: SecureRandom.uuid)
                }.to change {
                ActiveJob::Base.queue_adapter.enqueued_jobs.count
                }.by 0
            end

            it 'creates a job to generate report' do
                stub_const("Stats::ROWS_PER_FRAGMENT", 1)
                expect {
                @report_another.run(report_guid: SecureRandom.uuid)
                }.to change {
                ActiveJob::Base.queue_adapter.enqueued_jobs.count
                }.by 4

                expect(@report_another.num_fragments).to eq 4
                expect(@report_another.data_size).to eq 4
                expect(@report_another.etl).to eq true
                expect(@report_another.status).to eq Stats::BaseReport::WAITING
                expect(@report_another.persist_results?).to eq true
            end
        end
    end  
  end
end