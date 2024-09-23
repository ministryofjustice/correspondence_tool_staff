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
    let(:email_1) { "a.smith@email.com" }
    let(:email_2) { "b.jones@email.com" }
    let(:email_3) { "c.evans@gmail.com" }

    let(:contact_without_email) { build(:contact, data_request_emails: nil) }
    let(:contact_with_one_email) { build(:contact, data_request_emails: email_1) }
    let(:contact_with_two_emails) { build(:contact, data_request_emails: "#{email_1}\n#{email_2}") }
    let(:contact_with_two_emails_including_spaces) { build(:contact, data_request_emails: " #{email_1}    #{email_2}") }

    context "when there is a contact with no email" do
      subject(:data_request_area) { build :data_request_area, contact: contact_without_email }

      it { expect(data_request_area.recipient_emails).to eq [] }
    end

    context "when there is a contact with one email" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_one_email }

      it { expect(data_request_area.recipient_emails).to eq [email_1] }
    end

    context "when there is a contact with two emails" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_two_emails }

      it { expect(data_request_area.recipient_emails).to eq [email_1, email_2] }
    end

    context "when there is no contact" do
      subject(:data_request_area) { build :data_request_area }

      it { expect(data_request_area.recipient_emails).to eq [] }
    end

    context "when there is a contact with two emails, separated by many spaces" do
      subject(:data_request_area) { build :data_request_area, contact: contact_with_two_emails_including_spaces }

      it { expect(data_request_area.recipient_emails).to eq [email_1, email_2] }
    end
  end

  describe "#build_commissioning_document" do
    let(:data_request_area) { build(:data_request_area, data_request_area_type: "prison") }
    let(:mappa_data_request_area) { build(:data_request_area, data_request_area_type: "mappa") }

    it "builds a standard commissioning document template" do
      document = data_request_area.build_commissioning_document
      expect(document.template_name).to eq("standard")
    end

    it "builds a mappa commissioning document" do
      document = mappa_data_request_area.build_commissioning_document
      expect(document.template_name).to eq("mappa")
    end

    it "finds or initializes a commissioning document" do
      document = data_request_area.build_commissioning_document
      expect(document).to be_a(CommissioningDocument)
      expect(document.data_request_area).to eq(data_request_area)
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
