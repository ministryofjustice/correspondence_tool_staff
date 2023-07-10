require "rails_helper"

describe EmailStatusJob, type: :job do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    email = instance_double DataRequestEmail
    allow(SentryContextProvider).to receive(:set_context)
    allow(DataRequestEmail).to receive(:find).with(123).and_return(email)
    allow(email).to receive(:update_status!)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe ".perform" do
    it "sets the Raven environment" do
      described_class.perform_now(123)
      expect(SentryContextProvider).to have_received(:set_context)
    end

    it "queues the job" do
      expect { described_class.perform_later(123) }.to have_enqueued_job(described_class)
    end

    it "is in default queue" do
      expect(described_class.new.queue_name).to eq("correspondence_tool_staff_email_status")
    end

    it "executes perform" do
      email_1 = instance_double DataRequestEmail
      allow(DataRequestEmail).to receive(:find).with(123).and_return(email_1)
      expect(email_1).to receive(:update_status!)
      perform_enqueued_jobs { described_class.perform_later(123) }
    end
  end
end
