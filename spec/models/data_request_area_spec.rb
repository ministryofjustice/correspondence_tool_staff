# == Schema Information
#
# Table name: data_request_areas
#
#  id                     :bigint           not null, primary key
#  case_id                :bigint           not null
#  user_id                :bigint           not null
#  contact_id             :bigint
#  data_request_area_type :enum             not null
#  location               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require "rails_helper"

RSpec.describe DataRequestArea, type: :model do
  describe ".sent_and_in_progress_ids" do
    let(:in_progress_with_email) { create(:data_request_area, :in_progress) }

    before do
      # create 3 data requests that shouldn't be returned by method
      create(:data_request_area, :in_progress)
      create(:data_request_area, :completed)
      completed_with_email = create(:data_request_area, :completed)

      in_progress_with_email.commissioning_document.update!(sent_at: Date.current)
      completed_with_email.commissioning_document.update!(sent_at: Date.current)
    end

    it "returns ids of in progress sent data request areas" do
      expect(described_class.sent_and_in_progress_ids).to eq [in_progress_with_email.id]
    end
  end

  describe "#create" do
    context "with valid params" do
      subject(:data_request_area) do
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build_stubbed(:user),
          data_request_area_type: "prison",
          location: "X" * 500, # Max length
        )
      end

      it { is_expected.to be_valid }

      it "defaults to not started" do
        expect(data_request_area.status).to eq :not_started
      end
    end
  end

  describe "validation" do
    subject(:data_request_area) { build(:data_request_area, location: "HMP") }

    it { is_expected.to be_valid }

    it "requires data request area type" do
      data_request_area.data_request_area_type = nil
      expect(data_request_area).not_to be_valid
    end

    it "requires contact when there is no location" do
      data_request_area.location = nil
      data_request_area.contact_id = nil
      expect(data_request_area.valid?).to be false
    end

    it "requires a creating user" do
      data_request_area.user = nil
      expect(data_request_area).not_to be_valid
    end

    it "requires a case" do
      data_request_area.offender_sar_case = nil
      expect(data_request_area).not_to be_valid
    end
  end

  describe "#data_request_area_type" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:data_request_area, data_request_area_type: "prison")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "probation")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "branston")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "branston_registry")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "mappa")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "security")).to be_valid
        expect(build_stubbed(:data_request_area, data_request_area_type: "other_department")).to be_valid
      end
    end

    context "with invalid value" do
      it "raises an error" do
        expect {
          build_stubbed(:data_request_area, data_request_area_type: "user")
        }.to raise_error ArgumentError
      end
    end

    context "when nil" do
      it "is invalid and returns an error message" do
        data_request_area = build_stubbed(:data_request_area, data_request_area_type: nil)
        expect(data_request_area).not_to be_valid
        expect(data_request_area.errors[:data_request_area_type]).to eq ["Select what data you are requesting"]
      end
    end
  end

  describe "#location" do
    context "with valid values" do
      it "does not error" do
        expect(build_stubbed(:data_request_area, location: "HMP")).to be_valid
      end
    end

    context "when nil" do
      it "is invalid and returns an error message" do
        data_request_area = build_stubbed(:data_request_area, contact: nil, location: nil)
        expect(data_request_area).not_to be_valid
        expect(data_request_area.errors[:location]).to eq ["cannot be blank"]
      end
    end
  end

  describe "#status" do
    context "when data request area has no data request items" do
      let(:data_request_area) { build(:data_request_area) }

      it "returns 'Not started'" do
        expect(data_request_area.status).to eq :not_started
      end
    end

    context "when data request area has unfinished data request items" do
      let(:data_request_area) { create(:data_request_area) }

      before do
        create(:data_request, completed: false, data_request_area:)
      end

      it "returns 'In progress'" do
        expect(data_request_area.status).to eq :in_progress
      end
    end

    context "when data request is completed" do
      let(:data_request_area) { create(:data_request_area) }
      let!(:data_request) { create(:data_request, :completed, cached_date_received: Date.new(2024, 8, 13), data_request_area:) } # rubocop:disable RSpec/LetSetup

      it "returns 'Completed'" do
        expect(data_request_area.status).to eq :completed
      end
    end
  end

  describe "#recipient_emails" do
    let(:email_a) { "a.smith@email.com" }
    let(:email_b) { "b.jones@email.com" }
    let(:email_c) { "c.evans@gmail.com" }

    let(:contact_without_email) { build(:contact, data_request_emails: nil) }
    let(:contact_with_one_email) { build(:contact, data_request_emails: email_a) }
    let(:contact_with_two_emails) { build(:contact, data_request_emails: "#{email_a}\n#{email_b}") }
    let(:contact_with_two_emails_including_spaces) { build(:contact, data_request_emails: " #{email_a}    #{email_b}") }

    context "when there is a contact with no email" do
      subject(:data_request_area) { build :data_request_area, contact: contact_without_email }

      it { expect(data_request_area.recipient_emails).to eq [] }
    end

    context "when there is a contact with one email" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_one_email }

      it { expect(data_request_area.recipient_emails).to eq [email_a] }
    end

    context "when there is a contact with two emails" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_two_emails }

      it { expect(data_request_area.recipient_emails).to eq [email_a, email_b] }
    end

    context "when there is no contact" do
      subject(:data_request_area) { build :data_request_area }

      it { expect(data_request_area.recipient_emails).to eq [] }
    end

    context "when there is a contact with two emails, separated by many spaces" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_two_emails_including_spaces }

      it { expect(data_request_area.recipient_emails).to eq [email_a, email_b] }
    end

    context "when the request is esclated" do
      context "when not prison request" do
        subject(:data_request_area) { build :data_request_area, contact: contact_with_two_emails }

        it { expect(data_request_area.recipient_emails).to eq [email_a, email_b] }
      end

      context "when prison request" do
        let(:contact_without_email_and_with_escalation_email) { build(:contact, data_request_emails: nil, escalation_emails: email_a) }
        let(:contact_without_escalation_email) { build(:contact, data_request_emails: email_a, escalation_emails: nil) }
        let(:contact_with_one_escalation_email) { build(:contact, data_request_emails: email_a, escalation_emails: email_b) }
        let(:contact_with_two_escalation_emails) { build(:contact, data_request_emails: email_a, escalation_emails: "#{email_b}\n#{email_c}") }
        let(:contact_with_two_escalation_emails_including_spaces) { build(:contact, data_request_emails: email_a, escalation_emails: " #{email_b}    #{email_c}") }

        context "when contact has no normal email and one escalation email" do
          subject(:data_request_area) { build :data_request_area, contact: contact_without_email_and_with_escalation_email }

          it { expect(data_request_area.recipient_emails(escalated: true)).to eq [email_a] }
        end

        context "when contact has no escalation email" do
          subject(:data_request_area) { build :data_request_area, contact: contact_without_escalation_email }

          it { expect(data_request_area.recipient_emails(escalated: true)).to eq [email_a] }
        end

        context "when contact has one escalation email" do
          subject(:data_request_area) { build :data_request_area, contact: contact_with_one_escalation_email }

          it { expect(data_request_area.recipient_emails(escalated: true)).to eq [email_a, email_b] }
        end

        context "when contact has two escalation emails" do
          subject(:data_request_area) { build :data_request_area, contact: contact_with_two_escalation_emails }

          it { expect(data_request_area.recipient_emails(escalated: true)).to eq [email_a, email_b, email_c] }
        end

        context "when there is a contact with two escalation emails, separated by many spaces" do
          subject(:data_request_area) { build :data_request_area, contact: contact_with_two_escalation_emails_including_spaces }

          it { expect(data_request_area.recipient_emails(escalated: true)).to eq [email_a, email_b, email_c] }
        end
      end
    end
  end

  describe "#commissioning_email_sent?" do
    let(:data_request_area) { create(:data_request_area) }

    context "when commissioning_email sent" do
      before do
        data_request_area.commissioning_document.update(sent_at: Date.current)
      end

      it "returns true" do
        expect(data_request_area.commissioning_email_sent?).to be true
      end
    end

    context "when commissioning_email not sent" do
      before do
        data_request_area.commissioning_document.update(sent_at: nil)
      end

      it "returns false" do
        expect(data_request_area.commissioning_email_sent?).to be false
      end
    end
  end

  describe "#next_chase_number" do
    let(:data_request_area) { create(:data_request_area) }

    context "when no chases have been sent" do
      it "returns 0" do
        expect(data_request_area.next_chase_number).to eq 1
      end
    end

    context "when chase process has already started" do
      let(:last_chase) { 1 }

      before do
        create(:data_request_email, data_request_area:, email_type: "chase", chase_number: last_chase)
      end

      it "increments current chase number" do
        expect(data_request_area.next_chase_number).to eq last_chase + 1
      end
    end
  end

  describe "#chase_due?" do
    let(:data_request_area) { create(:data_request_area) }

    context "when next chase is today" do
      it "returns true" do
        allow(data_request_area).to receive(:next_chase_date).and_return(Time.current)
        expect(data_request_area.chase_due?).to be true
      end
    end

    context "when next chase is not today" do
      it "returns false" do
        allow(data_request_area).to receive(:next_chase_date).and_return(Date.current + 1.day)
        expect(data_request_area.chase_due?).to be false
      end
    end
  end

  describe "#create_commissioning_document" do
    context "when a new data request area is created" do
      it "creates a standard commissioning document with the correct template" do
        data_request_area = create(:data_request_area, data_request_area_type: "prison")
        document = data_request_area.commissioning_document

        expect(document).to be_present
        expect(document.template_name).to eq("standard")
      end

      it "creates a mappa commissioning document for mappa data request area" do
        data_request_area = create(:data_request_area, data_request_area_type: "mappa")
        document = data_request_area.commissioning_document

        expect(document).to be_present
        expect(document.template_name).to eq("mappa")
      end
    end
  end

  describe "associations" do
    context "with dependent data_requests" do
      let(:data_request_area) { create(:data_request_area) }

      before do
        create(:data_request, data_request_area:)
      end

      it "destroys associated data_requests when data_request_area is destroyed" do
        expect { data_request_area.destroy }.to change(DataRequest, :count).by(-1)
      end
    end

    context "with dependent commissioning_documents" do
      let(:data_request_area) { create(:data_request_area) }

      before do
        create(:commissioning_document, data_request_area:)
      end

      it "destroys associated commissioning_document when data_request_area is destroyed" do
        expect { data_request_area.destroy }.to change(CommissioningDocument, :count).by(-1)
      end
    end
  end

  describe "#clean_attributes" do
    subject(:data_request_area) { build :data_request_area }

    it "ensures string attributes do not have leading/trailing spaces" do
      data_request_area.location = "  The location"
      data_request_area.send(:clean_attributes)
      expect(data_request_area.location).to eq "The location"
    end

    it "ensures string attributes have the first letter capitalised" do
      data_request_area.location = "leicester"
      data_request_area.send(:clean_attributes)
      expect(data_request_area.location).to eq "Leicester"
    end
  end
end
