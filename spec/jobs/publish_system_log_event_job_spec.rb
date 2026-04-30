require "rails_helper"

RSpec.describe PublishSystemLogEventJob, type: :job do
  include ActiveJob::TestHelper

  let(:event_store) { instance_double(RailsEventStore::Client, publish: true) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(Rails.configuration).to receive(:event_store).and_return(event_store)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  describe ".perform" do
    it "queues the job" do
      expect {
        described_class.perform_later("Events::EmailSent", data: { recipient: "test@test.com" })
      }.to have_enqueued_job(described_class)
    end

    it "uses the email_status queue" do
      expect(described_class.new.queue_name).to eq("correspondence_tool_staff_email_status")
    end

    it "publishes the event to the event store" do
      expect(event_store).to receive(:publish) do |event|
        expect(event).to be_a(Events::EmailSent)
        expect(event.data).to include(recipient: "test@test.com", status: "delivered")
      end

      described_class.perform_now("Events::EmailSent", data: { "recipient" => "test@test.com", "status" => "delivered" })
    end
  end
end
