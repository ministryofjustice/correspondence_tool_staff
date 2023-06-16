require "rails_helper"

describe Warehouse::PurgeReportsJob, type: :job do
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

    it "is in the warehouse queue" do
      expect(job.queue_name).to eq("correspondence_tool_staff_reports")
    end

    it "destroys existing reports" do
      create :report
      expect(Report.all.size).to be > 0

      expect { job.perform }.to change { Report.all.size }.to(0)
    end
  end
end
