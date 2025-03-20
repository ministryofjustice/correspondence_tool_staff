require "rails_helper"

describe RequestPersonalInformationDeleteJob, type: :job do
  include ActiveJob::TestHelper

  let!(:for_deletion) { create(:personal_information_request, created_at: 4.months.ago) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(SentryContextProvider).to receive(:set_context)

    create_list(:personal_information_request, 5)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe ".perform" do
    it "sets the Sentry environment" do
      described_class.perform_now
      expect(SentryContextProvider).to have_received(:set_context)
    end

    it "queues the job" do
      expect { described_class.perform_later }.to have_enqueued_job(described_class)
    end

    it "is in expected queue" do
      expect(described_class.new.queue_name).to eq("correspondence_tool_staff_rpi")
    end

    it "executes perform and deletes objects" do
      expect(PersonalInformationRequest.count).to eq 6
      perform_enqueued_jobs { described_class.perform_later }
      expect(PersonalInformationRequest.count).to eq 5
      expect(for_deletion.reload).to be_deleted
    end
  end
end
