require "rails_helper"

RSpec.describe CommissioningDocumentEmailService do
  let(:responder) { find_or_create :sar_responder }
  let(:kase) { create(:offender_sar_case, responder:) }
  let(:contact) { create(:contact, data_request_emails: "test@test.com\ntest1@test.com", escalation_emails: "escalation@test.com") }
  let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, contact:) }
  let(:commissioning_document) { create(:commissioning_document) }
  let(:user) { kase.responder }
  let(:attachment) { create(:commissioning_document_attachment) }
  let(:uploader) { instance_double(S3Uploader, upload_file_to_case: attachment) }
  let(:mailer) { double CommissioningDocumentMailer } # rubocop:disable RSpec/VerifiedDoubles
  let(:service) do
    described_class.new(
      data_request_area:,
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
      expect(CommissioningDocumentMailer).to receive(:commissioning_email).twice.and_return(mailer)
      expect(mailer).to receive(:deliver_later!).twice
      service.send!
    end

    it "uses the expected queue" do
      expect {
        service.send!
      }.to(
        have_enqueued_job.on_queue("correspondence_tool_staff_mailers").at_least(2).times,
      )
    end

    it "sets commissioning document sent_at date" do
      service.send!
      expect(commissioning_document.sent_at).to be_present
    end

    it "adds a case history entry" do
      service.send!
      transistion = kase.transitions.last
      expect(transistion.event).to eq "send_day_1_email"
      expect(transistion.metadata["message"]).to eq "Prison requested from #{contact.name}"
    end
  end

  describe "#send_chase!" do
    let(:existing_attachment) { create(:commissioning_document_attachment) }

    before do
      commissioning_document.update!(attachment: existing_attachment)
    end

    describe "when initial chase" do
      let(:chase_type) { DataRequestChase::STANDARD_CHASE }

      it "removes the existing file from the commissioning document" do
        expect(existing_attachment).to receive(:destroy!)
        service.send_chase!(chase_type)
      end

      it "adds the file to the commissioning document" do
        service.send_chase!(chase_type)
        commissioning_document.reload
        expect(commissioning_document.attachment).to be_present
        expect(commissioning_document.attachment.id).not_to eq existing_attachment.id
      end

      it "sends an email for every contact email address excluding escalation emails" do
        expect(CommissioningDocumentMailer).to receive(chase_type).twice.and_return(mailer)
        expect(mailer).to receive(:deliver_later!).twice
        service.send_chase!(chase_type)
      end

      it "uses the expected queue" do
        expect {
          service.send_chase!(chase_type)
        }.to(
          have_enqueued_job.on_queue("correspondence_tool_staff_mailers").at_least(2).times,
        )
      end

      it "adds a case history entry" do
        service.send_chase!(chase_type)

        transistion = kase.transitions.last
        expect(transistion.event).to eq "send_chase_email"
        expect(transistion.metadata["message"]).to eq "Prison requested from #{contact.name}"
      end
    end

    describe "when escalation chase" do
      let(:chase_type) { DataRequestChase::ESCALATION_CHASE }

      it "sends an email for every contact email address including escalation emails" do
        expect(CommissioningDocumentMailer).to receive(chase_type).exactly(3).times.and_return(mailer)
        expect(mailer).to receive(:deliver_later!).exactly(3).times
        service.send_chase!(chase_type)
      end
    end

    describe "when overdue chase" do
      let(:chase_type) { DataRequestChase::OVERDUE_CHASE }

      it "sends an email for every contact email address including escalation emails" do
        expect(CommissioningDocumentMailer).to receive(chase_type).exactly(3).times.and_return(mailer)
        expect(mailer).to receive(:deliver_later!).exactly(3).times
        service.send_chase!(chase_type)
      end
    end
  end
end
