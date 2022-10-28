require 'rails_helper'

describe CommissioningDocumentTemplateService do
  let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: "Robert Badson").decorate }
  let(:data_request) { FactoryBot.build(:data_request, offender_sar_case: offender_sar_case) }
  let(:template_type) { :prison }
  subject { described_class.new(data_request: data_request, template_type: template_type) }

  describe '#initialize' do
    it 'requires a case and user' do
      expect(subject.instance_variable_get(:@template_type)).to eq template_type
      expect(subject.instance_variable_get(:@data_request)).to eq data_request
    end
  end

  describe '#call' do
    context "called with invalid data_request" do
      let(:data_request) { Object.new }
      it "sets result to :error without a valid DataRequest object" do
        subject.call
        expect(subject.result).to eq :error
      end
    end

    context "called with invalid template_type" do
      let(:template_type) { :invalid }
      it "sets result to :error without a valid template type" do
        subject.call
        expect(subject.result).to eq :error
      end
    end

    context "called with valid arguments" do
      it "sets result to :ok" do
        subject.call
        expect(subject.result).to eq :ok
      end

      describe "setting filename" do
        it "sets the filename as expected" do
          Timecop.freeze(Time.new(2022, 10, 27, 9, 20)) do
            number = offender_sar_case.number
            subject.call
            expect(subject.filename).to eq "Day1_HMPS_#{number}_Robert-Badson_20221027T0920.docx"
          end
        end
      end

      describe "setting mime type" do
        it "sets the mimie type as expected" do
          subject.call
          expect(subject.mime_type).to eq :docx
        end
      end

      describe "creating document" do
        it "outputs the document as a string" do
          subject.call
          expect(subject.document).to be_a(String)
        end
      end
    end
  end
end
