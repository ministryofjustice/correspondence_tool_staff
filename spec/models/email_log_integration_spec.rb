require "rails_helper"

RSpec.describe "Email Logging Integration", type: :model do
  include ActiveJob::TestHelper

  describe "EmailLoggingInterceptor" do
    let(:mail_message) do
      message = Mail::Message.new
      message.to = "recipient@example.com"
      message.from = "sender@example.com"
      message.subject = "Test Subject"
      message.message_id = "<test-#{SecureRandom.uuid}@example.com>"
      allow(message).to receive(:delivery_handler).and_return(TestMailer)
      allow(message).to receive(:action_name).and_return("test_email")
      message
    end

    it "creates an EmailLog entry when intercepting email" do
      expect {
        EmailLoggingInterceptor.delivering_email(mail_message)
      }.to change(EmailLog, :count).by(1)
    end

    it "creates log with pending status" do
      EmailLoggingInterceptor.delivering_email(mail_message)
      log = EmailLog.last

      expect(log.status).to eq "pending"
      expect(log.reference_id).to eq mail_message.message_id
    end

    it "stores email metadata" do
      EmailLoggingInterceptor.delivering_email(mail_message)
      log = EmailLog.last

      expect(log.to).to eq "recipient@example.com"
      expect(log.from).to eq "sender@example.com"
      expect(log.subject).to eq "Test Subject"
    end

    it "does not prevent email delivery on logging error" do
      allow(EmailLog).to receive(:create!).and_raise(StandardError, "DB error")
      allow(Rails.logger).to receive(:error)

      expect {
        EmailLoggingInterceptor.delivering_email(mail_message)
      }.not_to raise_error
    end
  end

  describe "email logging lifecycle" do
    let(:message_id) { "<lifecycle-test-#{SecureRandom.uuid}@example.com>" }
    let!(:email_log) do
      create(:email_log,
             reference_id: message_id,
             status: "pending",
             source: "TestMailer",
             action: "notify")
    end

    context "when delivery succeeds" do
      it "updates log to success status" do
        email_log.complete!(duration: 100.5)

        expect(email_log.reload.status).to eq "success"
        expect(email_log.completed_at).to be_present
        expect(email_log.duration_ms).to eq 100.5
      end
    end

    context "when delivery fails" do
      it "updates log to failed status with error message" do
        email_log.fail!("Net::SMTPAuthenticationError: Authentication failed", duration: 50.0)

        expect(email_log.reload.status).to eq "failed"
        expect(email_log.error_message).to include "Authentication failed"
        expect(email_log.duration_ms).to eq 50.0
      end
    end
  end

  describe "background job email logging" do
    # This test demonstrates the expected flow when emails are sent from background jobs
    # The actual mail delivery is mocked to avoid external dependencies

    let(:job_class) do
      Class.new(ApplicationJob) do
        queue_as :default

        def perform(email_address, subject)
          mail = Mail::Message.new
          mail.to = email_address
          mail.from = "system@example.com"
          mail.subject = subject
          mail.message_id = "<job-test-#{SecureRandom.uuid}@example.com>"

          # Simulate what happens when the interceptor is registered
          EmailLog.create!(
            reference_id: mail.message_id,
            source: "BackgroundMailer",
            action: "job_notification",
            status: "pending",
            metadata: {
              "to" => email_address,
              "from" => "system@example.com",
              "subject" => subject,
            },
          )

          # Simulate successful delivery
          log = EmailLog.find_by(reference_id: mail.message_id)
          log.complete!(duration: 123.45)
        end
      end
    end

    it "creates and completes email log during job execution" do
      expect {
        job_class.perform_now("user@example.com", "Job notification")
      }.to change(EmailLog, :count).by(1)

      log = EmailLog.last
      expect(log.status).to eq "success"
      expect(log.to).to eq "user@example.com"
      expect(log.subject).to eq "Job notification"
      expect(log.source).to eq "BackgroundMailer"
      expect(log.completed_at).to be_present
    end

    it "logs failed email delivery in job" do
      failing_job_class = Class.new(ApplicationJob) do
        queue_as :default

        def perform(email_address)
          mail = Mail::Message.new
          mail.to = email_address
          mail.message_id = "<failing-job-#{SecureRandom.uuid}@example.com>"

          EmailLog.create!(
            reference_id: mail.message_id,
            source: "BackgroundMailer",
            action: "failing_notification",
            status: "pending",
            metadata: { "to" => email_address, "from" => "system@example.com", "subject" => "Test" },
          )

          # Simulate failed delivery
          log = EmailLog.find_by(reference_id: mail.message_id)
          log.fail!("Connection refused", duration: 5000.0)
        end
      end

      failing_job_class.perform_now("user@example.com")

      log = EmailLog.last
      expect(log.status).to eq "failed"
      expect(log.error_message).to eq "Connection refused"
      expect(log.duration_ms).to eq 5000.0
    end
  end

  describe "querying email logs" do
    before do
      create(:email_log, status: "pending", created_at: 1.hour.ago)
      create(:email_log, :successful, created_at: 30.minutes.ago)
      create(:email_log, :failed, created_at: 10.minutes.ago)
      create(:system_log) # Non-email log should not appear
    end

    it "returns only email logs via EmailLog scope" do
      expect(EmailLog.count).to eq 3
    end

    it "filters by status" do
      expect(EmailLog.pending.count).to eq 1
      expect(EmailLog.successful.count).to eq 1
      expect(EmailLog.failed.count).to eq 1
    end

    it "returns recent logs in descending order" do
      recent = EmailLog.recent
      expect(recent.first.status).to eq "failed" # Most recent
      expect(recent.last.status).to eq "pending" # Oldest
    end
  end
end

# Dummy class for testing
class TestMailer; end
