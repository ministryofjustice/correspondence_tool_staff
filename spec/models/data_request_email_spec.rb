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
end
