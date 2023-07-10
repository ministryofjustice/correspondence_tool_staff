require "rails_helper"

RSpec.describe DataRequestEmail, type: :model do
  describe ".delivering" do
    it "returns created email" do
      data_request_email = create(:data_request_email, status: "created")
      expect(described_class.delivering).to include data_request_email
    end

    it "returns email that is sending" do
      data_request_email = create(:data_request_email, status: "sending")
      expect(described_class.delivering).to include data_request_email
    end

    it "does not return delivered email" do
      data_request_email = create(:data_request_email, status: "delivered")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a permanent failure" do
      data_request_email = create(:data_request_email, status: "permanent-failure")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a temporary failure" do
      data_request_email = create(:data_request_email, status: "temporary-failure")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "does not return email with a technical failure" do
      data_request_email = create(:data_request_email, status: "technical-failure")
      expect(described_class.delivering).not_to include data_request_email
    end

    it "returns email created within last 7 days" do
      data_request_email = create(:data_request_email, status: "created", created_at: Time.zone.today - 6.days)
      expect(described_class.delivering).to include data_request_email
    end

    it "does not return email created more than 7 days ago" do
      data_request_email = create(:data_request_email, status: "created", created_at: Time.zone.today - 8.days)
      expect(described_class.delivering).not_to include data_request_email
    end
  end

  describe "#update_status!" do
    let(:notify_client) { instance_double(Notifications::Client) }
    let(:client_response) { OpenStruct.new(status: "delivered") }
    let(:email) { create(:data_request_email) }

    before do
      allow(Notifications::Client).to receive(:new).and_return(notify_client)
      allow(notify_client).to receive(:get_notification).with(email.notify_id).and_return(client_response)
    end

    context "when email status needs updating" do
      it "updates the status" do
        expect { email.update_status! }.to change(email, :status).to "delivered"
      end
    end

    context "when email status should not be updated" do
      let(:email) { create(:data_request_email, created_at: 1.month.ago) }

      it "does not update the status" do
        expect { email.update_status! }.not_to(change(email, :status))
      end
    end
  end
end
