require "rails_helper"

describe CommissioningDocumentEmailService do
  let(:responder) { find_or_create :sar_responder }
  let(:kase) { create(:offender_sar_case, responder:) }
  let(:contact) { create(:contact, data_request_emails: "test@test.com\ntest1@test.com") }
  let(:data_request) { create(:data_request, offender_sar_case: kase, contact:) }
  let(:commissioning_document) { create(:commissioning_document) }
  let(:user) { kase.responder }
  let(:attachment) { create(:commissioning_document_attachment) }
  let(:uploader) { instance_double(S3Uploader, upload_file_to_case: attachment) }
  let(:mailer) { double ActionNotificationsMailer } # rubocop:disable RSpec/VerifiedDoubles
  let(:service) do
    described_class.new(
      data_request:,
      current_user: responder,
      commissioning_document:,
    )
  end

  before do
    allow(S3Uploader).to receive(:new).and_return(uploader)
  end

  describe "#send!" do
    it "adds the file to the commissioning document" do
      expect {
        service.send!
      }.to change(commissioning_document, :attachment)
    end

    it "sends an email for every contact email address" do
      expect(ActionNotificationsMailer).to receive(:commissioning_email).twice.and_return(mailer)
      expect(mailer).to receive(:deliver_later).twice
      service.send!
    end

    it "sets commissioning document as sent" do
      service.send!
      expect(commissioning_document.sent).to be_truthy
    end

    it "adds a case history entry" do
      service.send!
      transistion = kase.transitions.last
      expect(transistion.event).to eq "send_day_1_email"
      expect(transistion.metadata["message"]).to eq "Prison records requested from #{contact.name}"
    end

    context "when branston archives require an email" do
      before do
        data_request.update!(email_branston_archives: true)
      end

      it "also sends an email to branston archives" do
        expect(ActionNotificationsMailer).to receive(:commissioning_email).exactly(3).times.and_return(mailer)
        expect(mailer).to receive(:deliver_later).exactly(3).times
        service.send!
      end
    end
  end
end
