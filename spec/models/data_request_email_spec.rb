# == Schema Information
#
# Table name: data_request_emails
#
#  id                   :bigint           not null, primary key
#  data_request_id      :bigint
#  email_type           :integer          default("commissioning_email")
#  email_address        :string
#  notify_id            :string
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  data_request_area_id :bigint
#
require "rails_helper"

RSpec.describe DataRequestEmail, type: :model do
  include ActiveJob::TestHelper

  let(:job) { class_double(EmailStatusJob) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe ".recent" do
    it "returns email created within last 7 days" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "created", created_at: Time.zone.today - 6.days)
      expect(described_class.recent).to include data_request_email
    end

    it "does not return email created more than 7 days ago" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "created", created_at: Time.zone.today - 8.days)
      expect(described_class.recent).not_to include data_request_email
    end
  end

  describe ".sent_to_notify" do
    it "returns email with notify_id" do
      data_request_email = create(:data_request_email, :sent_to_notify)
      expect(described_class.sent_to_notify).to include data_request_email
    end

    it "does not return email without notify_id" do
      data_request_email = create(:data_request_email)
      expect(described_class.sent_to_notify).not_to include data_request_email
    end
  end

  describe ".delivering" do
    it "returns created email" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "created")
      expect(described_class.delivering).to include data_request_email
    end

    it "returns email that is sending" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "sending")
      expect(described_class.delivering).to include data_request_email
    end

    it "does not return delivered email" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "delivered")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a permanent failure" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "permanent-failure")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a temporary failure" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "temporary-failure")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a technical failure" do
      data_request_email = create(:data_request_email, :sent_to_notify, status: "technical-failure")
      expect(described_class.delivering).not_to include data_request_email
    end
  end

  context "when created" do
    it "queues a job with a delay" do
      allow(EmailStatusJob).to receive(:set).with(wait: 15.seconds).and_return(job)
      expect(job).to receive(:perform_later)
      create(:data_request_email)
    end

    it "publishes an email queued event" do
      allow(EmailStatusJob).to receive(:set).with(wait: 15.seconds).and_return(job)
      allow(job).to receive(:perform_later)

      expect {
        create(:data_request_email)
      }.to have_enqueued_job(PublishSystemLogEventJob).with(
        Events::EmailQueued.name,
        data: hash_including(
          category: "commissioning_document",
          email_type: "commissioning_email",
          recipient: "test@user.com",
          recipient_type: "external",
          status: "created",
        ),
      )
    end
  end

  describe "#update_status_with_delay" do
    it "queues a job with a delay" do
      data_request_email = create(:data_request_email)

      allow(EmailStatusJob).to receive(:set).with(wait: 15.seconds).and_return(job)
      expect(job).to receive(:perform_later)

      data_request_email.update_status_with_delay
    end
  end

  describe "#update_status!" do
    let(:notify_client) { instance_double(Notifications::Client) }
    let(:client_response) { OpenStruct.new(status: "delivered") }
    let(:email) { create(:data_request_email, :sent_to_notify) }

    before do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(notify_client).to receive(:get_notification).with(email.notify_id).and_return(client_response)
    end

    context "when email status needs updating" do
      it "updates the status" do
        expect { email.update_status! }.to change(email, :status).to "delivered"
      end

      it "publishes an email delivered event" do
        expect {
          email.update_status!
        }.to have_enqueued_job(PublishSystemLogEventJob).with(
          Events::EmailDelivered.name,
          data: hash_including(
            category: "commissioning_document",
            email_type: "commissioning_email",
            notify_id: email.notify_id,
            previous_status: "created",
            recipient: email.email_address,
            status: "delivered",
          ),
        )
      end
    end

    context "when email status should not be updated" do
      let(:email) { create(:data_request_email, :sent_to_notify, created_at: 1.month.ago) }

      it "does not update the status" do
        expect { email.update_status! }.not_to(change(email, :status))
      end
    end

    context "when email delivery fails" do
      let(:client_response) { OpenStruct.new(status: "permanent-failure") }

      it "publishes an email failed event" do
        expect {
          email.update_status!
        }.to have_enqueued_job(PublishSystemLogEventJob).with(
          Events::EmailFailed.name,
          data: hash_including(
            category: "commissioning_document",
            email_type: "commissioning_email",
            notify_id: email.notify_id,
            previous_status: "created",
            recipient: email.email_address,
            status: "permanent-failure",
          ),
        )
      end
    end
  end
end
