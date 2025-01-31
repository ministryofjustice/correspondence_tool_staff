require "rails_helper"

describe DataRequestEmailDecorator, type: :model do
  let(:data_request_email) { create(:data_request_email).decorate }

  describe "#email_type" do
    it "gets translation for email type" do
      expect(data_request_email.email_type).to eq "Day 1 commissioning email"
    end

    context "when a chase email" do
      let(:data_request_email) { create(:data_request_email, email_type: :chase_escalation, chase_number: 8).decorate }

      it "includes the chase number" do
        expect(data_request_email.email_type).to eq "Chase 8 escalated - Automated email"
      end
    end
  end

  describe "#created_at" do
    it "formats the created at date and time" do
      Timecop.freeze Time.zone.local(2023, 1, 30, 15, 52, 22) do
        expect(data_request_email.created_at).to eq "30 Jan 2023 15:52"
      end
    end
  end

  describe "#status" do
    it "formats the status" do
      expect(data_request_email.status).to eq "Created"
    end
  end
end
