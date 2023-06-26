require "rails_helper"

class DummyWrongTestFirst
  def initialize(**options); end
end

class DummyWrongTestSecond
  def initialize; end
end

class DummyReportTest
  def initialize(**options); end

  def process(offset, report_job_guid = nil); end
end

describe PerformanceReportJob, type: :job do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(SentryContextProvider).to receive(:set_context)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe "#perform" do
    let(:job) { described_class.new }
    let(:user) { find_or_create :default_press_officer }

    it "is in the report_job queue" do
      expect(job.queue_name).to eq("correspondence_tool_staff_performance_report")
    end

    it "logs to Rails logger if a report related class string does not exist" do
      expect(Rails.logger).to receive(:error).with(/NameError/)
      job.perform("NotExistingReportClass", "test", 0, 0, 0)
    end

    it "logs to Rails logger if the report class does not have process method" do
      expect(Rails.logger).to receive(:error).with(/NoMethodError/)
      job.perform("DummyWrongTestFirst", "test", 0, 0, 0)
    end

    it "performs later" do
      perform_enqueued_jobs do
        expect_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
          .to receive(:perform).with(
            "DummyReportTest", "test", 0, 0, 0
          )
        described_class.perform_later("DummyReportTest", "test", 0, 0, 0)
      end
    end

    it "process the report job" do
      dummyreport = DummyReportTest.new
      allow(DummyReportTest).to receive(:new).and_return(dummyreport)
      allow(dummyreport).to receive(:process)
      job.perform("DummyReportTest", "test", 0, 0, 0)

      expect(dummyreport).to have_received(:process)
    end
  end
end
