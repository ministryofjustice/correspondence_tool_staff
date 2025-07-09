# == Schema Information
#
# Table name: commissioning_documents
#
#  id                   :bigint           not null, primary key
#  data_request_id      :bigint
#  template_name        :enum
#  sent_at              :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  attachment_id        :bigint
#  data_request_area_id :bigint
#
require "rails_helper"

RSpec.describe CommissioningDocument, type: :model do
  subject(:commissioning_document) { described_class.new(data_request_area:) }

  let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: "Robert Badson").decorate }
  let(:data_request_area) { create(:data_request_area, offender_sar_case:) }
  let(:template_type) { :standard }

  it "can be created" do
    expect(commissioning_document).to be_present
  end

  describe "template validation" do
    context "when no template" do
      it "is not valid" do
        expect(commissioning_document).not_to be_valid
      end

      it "has one error" do
        commissioning_document.valid?
        expect(commissioning_document.errors.count).to eq 1
      end
    end

    context "with invalid template value" do
      it "is not valid" do
        expect {
          commissioning_document.template_name = :invalid
        }.to raise_error(ArgumentError)
      end

      it "has one error" do
        commissioning_document.valid?
        expect(commissioning_document.errors.count).to eq 1
      end
    end

    context "with valid template value" do
      before { commissioning_document.template_name = template_type }

      it "is valid" do
        expect(commissioning_document).to be_valid
      end
    end
  end

  describe "data request area validation" do
    context "with no data_request_area" do
      it "is not valid" do
        commissioning_document = build(:commissioning_document, data_request_area: nil)
        expect(commissioning_document).not_to be_valid
        expect(commissioning_document.errors[:data_request_area]).to include("is required")
      end
    end
  end

  describe "#document" do
    context "when invalid object" do
      it "returns nil" do
        expect(commissioning_document.document).to be_nil
      end
    end

    context "when valid object" do
      before { commissioning_document.template_name = template_type }

      it "outputs the document as a string" do
        expect(commissioning_document.document).to be_a(String)
      end
    end
  end

  describe "#filename" do
    context "when invalid object" do
      it "returns nil" do
        expect(commissioning_document.filename).to be_nil
      end
    end

    context "when valid object" do
      it "sets the filename as expected" do
        Timecop.freeze(Time.zone.local(2022, 10, 31, 9, 20)) do
          commissioning_document = described_class.new(data_request_area:)
          commissioning_document.template_name = template_type
          number = offender_sar_case.number
          expect(commissioning_document.filename).to eq "Day1_prison_#{number}_Robert-Badson_20221031T0920.docx"
        end
      end
    end
  end

  describe "setting mime type" do
    it "sets the mime type as expected" do
      expect(commissioning_document.mime_type).to eq :docx
    end
  end

  describe "#remove_attachment" do
    let(:attachment) { create(:commissioning_document_attachment) }

    before do
      commissioning_document.update(attachment:, template_name: template_type)
    end

    it "sets attachment to nil" do
      commissioning_document.remove_attachment
      expect(commissioning_document.attachment_id).to be_nil
    end

    it "destroys the attachment" do
      commissioning_document.remove_attachment
      expect { attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#has_no_request_area?" do
    context "when data_request_area is nil" do
      let(:data_request_area) { nil }

      it "returns true" do
        expect(commissioning_document.has_no_request_area?).to be true
      end
    end

    context "when data_request_area is present" do
      it "returns false" do
        expect(commissioning_document.has_no_request_area?).to be false
      end
    end
  end
end
