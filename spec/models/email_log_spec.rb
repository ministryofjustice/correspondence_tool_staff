# == Schema Information
#
# Table name: system_logs
#
#  id            :bigint           not null, primary key
#  type          :string           not null
#  status        :string           default("pending")
#  reference_id  :string
#  action        :string
#  source        :string
#  metadata      :jsonb            default({})
#  error_message :text
#  duration_ms   :float
#  completed_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require "rails_helper"

RSpec.describe EmailLog, type: :model do
  describe "factory" do
    it "produces a valid object by default" do
      email_log = build(:email_log)
      expect(email_log).to be_valid
    end

    it "has email-specific metadata" do
      email_log = build(:email_log)
      expect(email_log.to).to be_present
      expect(email_log.from).to be_present
      expect(email_log.subject).to be_present
    end
  end

  describe "inheritance" do
    it "inherits from SystemLog" do
      expect(described_class.superclass).to eq SystemLog
    end

    it "uses STI with type column" do
      email_log = create(:email_log)
      expect(email_log.type).to eq "EmailLog"
    end

    it "is retrievable via SystemLog" do
      email_log = create(:email_log)
      expect(SystemLog.find(email_log.id)).to be_a(described_class)
    end
  end

  describe "metadata accessors" do
    let(:email_log) do
      build(:email_log, metadata: {
        "to" => "recipient@example.com",
        "from" => "sender@example.com",
        "subject" => "Test Subject",
      })
    end

    describe "#to" do
      it "returns the to address from metadata" do
        expect(email_log.to).to eq "recipient@example.com"
      end
    end

    describe "#from" do
      it "returns the from address from metadata" do
        expect(email_log.from).to eq "sender@example.com"
      end
    end

    describe "#subject" do
      it "returns the subject from metadata" do
        expect(email_log.subject).to eq "Test Subject"
      end
    end
  end

  describe "source accessors" do
    let(:email_log) do
      build(:email_log,
            source: "ActionNotificationsMailer",
            action: "new_assignment",
            reference_id: "<abc123@mail.test>")
    end

    describe "#mailer_class" do
      it "returns the source as mailer class" do
        expect(email_log.mailer_class).to eq "ActionNotificationsMailer"
      end
    end

    describe "#mailer_action" do
      it "returns the action as mailer action" do
        expect(email_log.mailer_action).to eq "new_assignment"
      end
    end

    describe "#message_id" do
      it "returns the reference_id as message_id" do
        expect(email_log.message_id).to eq "<abc123@mail.test>"
      end
    end
  end

  describe ".create_from_message" do
    let(:mail_message) do
      message = double("Mail::Message") # rubocop:disable RSpec/VerifiedDoubles
      allow(message).to receive_messages(
        message_id: "<test-message-id@example.com>",
        to: ["recipient@example.com"],
        from: ["sender@example.com"],
        subject: "Test Email Subject",
        action_name: "test_action",
        delivery_handler: ActionNotificationsMailer,
      )
      message
    end

    it "creates an EmailLog from a mail message" do
      email_log = described_class.create_from_message(mail_message)

      expect(email_log).to be_persisted
      expect(email_log.reference_id).to eq "<test-message-id@example.com>"
      expect(email_log.source).to eq "ActionNotificationsMailer"
      expect(email_log.action).to eq "test_action"
      expect(email_log.status).to eq "pending"
    end

    it "stores email addresses in metadata" do
      email_log = described_class.create_from_message(mail_message)

      expect(email_log.to).to eq "recipient@example.com"
      expect(email_log.from).to eq "sender@example.com"
      expect(email_log.subject).to eq "Test Email Subject"
    end

    it "handles multiple recipients" do
      allow(mail_message).to receive(:to).and_return(["a@example.com", "b@example.com"])
      email_log = described_class.create_from_message(mail_message)

      expect(email_log.to).to eq "a@example.com, b@example.com"
    end
  end

  describe "scopes inherited from SystemLog" do
    let!(:pending_email) { create(:email_log, status: "pending") }
    let!(:successful_email) { create(:email_log, :successful) }
    let!(:failed_email) { create(:email_log, :failed) }

    it "returns only EmailLog records" do
      create(:system_log) # non-email log

      expect(described_class.all.count).to eq 3
      expect(described_class.all).to all(be_a(described_class))
    end

    it "supports pending scope" do
      expect(described_class.pending).to contain_exactly(pending_email)
    end

    it "supports successful scope" do
      expect(described_class.successful).to contain_exactly(successful_email)
    end

    it "supports failed scope" do
      expect(described_class.failed).to contain_exactly(failed_email)
    end
  end
end
