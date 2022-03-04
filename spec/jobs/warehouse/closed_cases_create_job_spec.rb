require 'rails_helper'

module TestJobForCloseReport
  class DummyWrongTestFirst
    def initialize(**options)
    end
  end

  class DummyReportTest < Stats::BaseClosedCasesReport
    def initialize(**options)
    end

    def process(report_guid:)
    end
  end
end

describe Warehouse::ClosedCasesCreateJob, type: :job do
  include ActiveJob::TestHelper

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    allow(SentryContextProvider).to receive(:set_context)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe '#perform' do
    let(:job) { described_class.new }
    let(:user) { find_or_create :default_press_officer }

    it 'is in the report_job queue' do
      expect(job.queue_name).to eq('correspondence_tool_staff_reports')
    end

    it 'logs to Rails logger if a report related class string does not exist' do
      expect(Rails.logger).to receive(:error).with(/NameError/)
      job.perform('NotExistingReportClass', 'test', 0, 0, 0)
    end

    it 'logs to Rails logger if the report class is not subclass of Stats::BaseClosedCasesReport' do
      expect(Rails.logger).to receive(:error).with("TestJobForCloseReport::DummyWrongTestFirst: is not subclass of Stats::BaseClosedCasesReport")
      job.perform('TestJobForCloseReport::DummyWrongTestFirst', 'test', 0, 0, 0)
    end

    it 'performs later' do
      perform_enqueued_jobs do
        expect_any_instance_of(described_class).to receive(:perform).with(
            "TestJobForCloseReport::DummyReportTest", "test", 0, 0, 0)
        described_class.perform_later("TestJobForCloseReport::DummyReportTest", "test", 0, 0, 0)
      end
    end

    it 'process the report job' do
      dummyreport = TestJobForCloseReport::DummyReportTest.new
      allow(TestJobForCloseReport::DummyReportTest).to receive(:new).and_return(dummyreport)
      allow(dummyreport).to receive(:process)
      job.perform("TestJobForCloseReport::DummyReportTest", "test", user.id, 0, 0)   
      
      expect(dummyreport).to have_received(:process)
    end
  end
end
