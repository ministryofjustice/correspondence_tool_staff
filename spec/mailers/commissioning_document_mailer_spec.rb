require "rails_helper"

RSpec.describe CommissioningDocumentMailer, type: :mailer do
  include ActiveJob::TestHelper

  describe "commissioning_email" do
    let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: "Subject name") }
    let(:data_request_area) { create(:data_request_area, offender_sar_case:) }
    let(:commissioning_document) { create(:commissioning_document, data_request_area:) }
    let(:email_address) { "test@test.com" }
    let(:kase_number) { "12345" }
    let(:mail) { described_class.commissioning_email(commissioning_document, kase_number, email_address) }

    before do
      ActiveJob::Base.queue_adapter = :test
    end

    it "sets the template" do
      expect(mail.govuk_notify_template)
        .to eq "94b66c61-feff-42f5-950d-d0af0a8205ef"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:email_address]).to eq email_address
      expect(mail.govuk_notify_personalisation[:deadline_text]).to eq I18n.t("mailer.commissioning_email.deadline", date: commissioning_document.deadline)
      expect(mail.govuk_notify_personalisation[:email_subject]).to include "Subject Access Request", "12345", "Day 1 commissioning", "Subject name"
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include email_address
    end

    it "creates a DataRequestEmail record" do
      expect {
        mail.deliver
      }.to change(DataRequestEmail, :count).by 1
    end

    it "publishes an email system log event" do
      expect {
        mail.deliver
      }.to have_enqueued_job(PublishSystemLogEventJob).with(
        Events::EmailSent.name,
        data: hash_including(
          case_number: kase_number,
          category: "commissioning_document",
          commissioning_document_id: commissioning_document.id,
          data_request_area_id: commissioning_document.data_request_area_id,
          email_type: "commissioning_email",
          recipient: email_address,
          recipient_type: "external",
        ),
      )
    end

    context "when email is retried" do
      it "doesn't create a new data_request_email record" do
        create(:data_request_email, email_address:, data_request_area: commissioning_document.data_request_area)

        expect {
          mail.deliver
        }.to change(DataRequestEmail, :count).by 0
      end
    end

    describe "#set_notify_id" do
      let(:data_request_email) { create(:data_request_email) }
      let(:notify_id) { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
      let(:message) do
        OpenStruct.new(
          govuk_notify_response: OpenStruct.new(id: notify_id),
        )
      end

      it "updates object with notify ID" do
        mailer = described_class.new
        allow(mailer).to receive(:message).and_return(message)
        allow(mailer).to receive(:data_request_email).and_return(data_request_email)

        mailer.send(:set_notify_id)
        expect(data_request_email.notify_id).to eq notify_id
      end
    end
  end

  describe "chase_email" do
    let(:kase) { create(:offender_sar_case) }
    let(:commissioning_document) { create(:commissioning_document) }
    let(:email_address) { "test@test.com" }
    let(:chase_number) { 1 }
    let(:mail) { described_class.chase_email(kase, commissioning_document, email_address, chase_number) }

    before do
      ActiveJob::Base.queue_adapter = :test
    end

    it "sets the template" do
      expect(mail.govuk_notify_template)
          .to eq "95b9af74-5037-4ec2-9e82-ee6fe1df6953"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:email_address]).to eq email_address
      expect(mail.govuk_notify_personalisation[:email_subject]).to eq "Subject Access Request - #{kase.number} - #{kase.subject_full_name} - Chase #{chase_number}"
      expect(mail.govuk_notify_personalisation[:deadline]).to eq commissioning_document.deadline
      expect(mail.govuk_notify_personalisation[:deadline_days]).to eq commissioning_document.deadline_days
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include email_address
    end

    it "creates a DataRequestEmail record" do
      expect {
        mail.deliver
      }.to change(DataRequestEmail, :count).by 1
    end

    it "publishes the chase email details to the system log" do
      expect {
        mail.deliver
      }.to have_enqueued_job(PublishSystemLogEventJob).with(
        Events::EmailSent.name,
        data: hash_including(
          case_number: kase.number,
          category: "commissioning_document",
          chase_number: chase_number,
          commissioning_document_id: commissioning_document.id,
          email_type: "chase",
          recipient: email_address,
        ),
      )
    end

    context "when email is retried" do
      it "doesn't create a new data_request_email record" do
        create(:data_request_chase_email, email_address:, data_request_area: commissioning_document.data_request_area)

        expect {
          mail.deliver
        }.to change(DataRequestEmail, :count).by 0
      end
    end

    describe "#set_notify_id" do
      let(:data_request_email) { create(:data_request_email) }
      let(:notify_id) { "35daaa7a-2859-4c39-a5f2-bfdb17a053f4" }
      let(:message) do
        OpenStruct.new(
          govuk_notify_response: OpenStruct.new(id: notify_id),
        )
      end

      it "updates object with notify ID" do
        mailer = described_class.new
        allow(mailer).to receive(:message).and_return(message)
        allow(mailer).to receive(:data_request_email).and_return(data_request_email)

        mailer.send(:set_notify_id)
        expect(data_request_email.notify_id).to eq notify_id
      end
    end
  end

  describe "chase_escalation_email" do
    let(:kase) { create(:offender_sar_case) }
    let(:commissioning_document) { create(:commissioning_document) }
    let(:email_address) { "test@test.com" }
    let(:chase_number) { 3 }
    let(:mail) { described_class.chase_escalation_email(kase, commissioning_document, email_address, chase_number) }

    it "sets the template" do
      expect(mail.govuk_notify_template)
          .to eq "09f631bc-58a2-4142-b4e8-43784646a7d1"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:email_address]).to eq email_address
      expect(mail.govuk_notify_personalisation[:email_subject]).to eq "Subject Access Request - #{kase.number} - #{kase.subject_full_name} - Chase #{chase_number}"
      expect(mail.govuk_notify_personalisation[:deadline]).to eq commissioning_document.deadline
      expect(mail.govuk_notify_personalisation[:deadline_days]).to eq commissioning_document.deadline_days
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include email_address
    end

    it "creates a DataRequestEmail record" do
      expect {
        mail.deliver
      }.to change(DataRequestEmail, :count).by 1
    end

    context "when email is retried" do
      it "doesn't create a new data_request_email record" do
        create(:data_request_email, email_address:, data_request_area: commissioning_document.data_request_area, email_type: "chase_escalation", chase_number:)

        expect {
          mail.deliver
        }.to change(DataRequestEmail, :count).by 0
      end
    end
  end

  describe "chase_overdue_email" do
    let(:kase) { create(:offender_sar_case) }
    let(:commissioning_document) { create(:commissioning_document) }
    let(:email_address) { "test@test.com" }
    let(:chase_number) { 8 }
    let(:mail) { described_class.chase_overdue_email(kase, commissioning_document, email_address, chase_number) }

    it "sets the template" do
      expect(mail.govuk_notify_template)
          .to eq "d20279ec-116c-492f-a7bb-130556b20247"
    end

    it "personalises the email" do
      expect(mail.govuk_notify_personalisation[:email_address]).to eq email_address
      expect(mail.govuk_notify_personalisation[:email_subject]).to eq "Subject Access Request - #{kase.number} - #{kase.subject_full_name} - Chase #{chase_number}"
      expect(mail.govuk_notify_personalisation[:deadline]).to eq commissioning_document.deadline
      expect(mail.govuk_notify_personalisation[:external_deadline]).to eq kase.external_deadline.strftime("%d/%m/%Y")
    end

    it "sets the To address of the email using the provided user" do
      expect(mail.to).to include email_address
    end

    it "creates a DataRequestEmail record" do
      expect {
        mail.deliver
      }.to change(DataRequestEmail, :count).by 1
    end

    context "when email is retried" do
      it "doesn't create a new data_request_email record" do
        create(:data_request_chase_email, email_address:, data_request_area: commissioning_document.data_request_area, email_type: "chase_overdue", chase_number:)

        expect {
          mail.deliver
        }.to change(DataRequestEmail, :count).by 0
      end
    end
  end
end
