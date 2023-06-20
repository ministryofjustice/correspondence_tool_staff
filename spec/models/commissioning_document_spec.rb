require "rails_helper"

RSpec.describe CommissioningDocument, type: :model do
  subject { described_class.new(data_request:) }

  let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: "Robert Badson").decorate }
  let(:data_request) { create(:data_request, offender_sar_case:) }
  let(:template_type) { :prison }

  it "can be created" do
    expect(subject).to be_present
  end

  describe "template validation" do
    context "when no template" do
      it "is not valid" do
        expect(subject).not_to be_valid
      end

      it "has one error" do
        subject.valid?
        expect(subject.errors.count).to eq 1
      end
    end

    context "with invalid template value" do
      it "is not valid" do
        expect {
          subject.template_name = :invalid
        }.to raise_error(ArgumentError)
      end

      it "has one error" do
        subject.valid?
        expect(subject.errors.count).to eq 1
      end
    end

    context "with valid template value" do
      before { subject.template_name = template_type }

      it "is valid" do
        expect(subject).to be_valid
      end
    end
  end

  describe "#document" do
    context "when invalid object" do
      it "returns nil" do
        expect(subject.document).to be_nil
      end
    end

    context "when valid object" do
      before { subject.template_name = template_type }

      it "outputs the document as a string" do
        expect(subject.document).to be_a(String)
      end
    end
  end

  describe "#filename" do
    context "when invalid object" do
      it "returns nil" do
        expect(subject.filename).to be_nil
      end
    end

    context "when valid object" do
      it "sets the filename as expected" do
        Timecop.freeze(Time.zone.local(2022, 10, 31, 9, 20)) do
          commissioning_document = described_class.new(data_request:)
          commissioning_document.template_name = template_type
          number = offender_sar_case.number
          expect(commissioning_document.filename).to eq "Day1_HMPS_#{number}_Robert-Badson_20221031T0920.docx"
        end
      end
    end
  end

  describe "setting mime type" do
    it "sets the mime type as expected" do
      expect(subject.mime_type).to eq :docx
    end
  end

  describe "#remove_attachment" do
    let(:attachment) { create(:commissioning_document_attachment) }

    before do
      subject.update(attachment:, template_name: template_type)
    end

    it "sets attachment to nil" do
      subject.remove_attachment
      expect(subject.attachment_id).to be_nil
    end

    it "destroys the attachment" do
      subject.remove_attachment
      expect { attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
