require "rails_helper"

describe PdfMakerJob, type: :job do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    attachment = instance_double CaseAttachment
    allow(SentryContextProvider).to receive(:set_context)
    allow(CaseAttachment).to receive(:find).with(123).and_return(attachment)
    allow(attachment).to receive(:make_preview)
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
      expect(described_class.new.queue_name).to eq("correspondence_tool_staff_pdf_maker")
    end

    it "executes perform" do
      attachment_1 = instance_double CaseAttachment
      allow(CaseAttachment).to receive(:find).with(123).and_return(attachment_1)
      expect(attachment_1).to receive(:make_preview)
      perform_enqueued_jobs { described_class.perform_later(123) }
    end
  end
end
