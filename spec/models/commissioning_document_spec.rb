require 'rails_helper'

RSpec.describe CommissioningDocument, type: :model do
  let(:offender_sar_case) { create(:offender_sar_case, subject_full_name: 'Robert Badson').decorate }
  let(:data_request) { FactoryBot.build(:data_request, offender_sar_case: offender_sar_case) }
  let(:template_type) { :prison }
  subject { described_class.new(data_request: data_request) }

  it 'can be created' do
    expect(subject).to be_present
  end

  describe 'template validation' do
    context 'no template' do
      it 'is not valid' do
        expect(subject).to_not be_valid
      end
    end

    context 'invalid template value' do
      before { subject.template_name = :invalid }

      it 'is not valid' do
        expect(subject).to_not be_valid
      end
    end

    context 'valid template value' do
      before { subject.template_name = template_type }

      it 'is not valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#document' do
    context 'invalid object' do
      it 'returns nil' do
        expect(subject.document).to be_nil
      end
    end

    context 'valid object' do
      before { subject.template_name = template_type }

      it 'outputs the document as a string' do
        expect(subject.document).to be_a(String)
      end
    end
  end

  describe '#filename' do
    context 'invalid object' do
      it 'returns nil' do
        expect(subject.filename).to be_nil
      end
    end

    context 'valid object' do
      it 'sets the filename as expected' do
        Timecop.freeze(Time.new(2022, 10, 27, 9, 20)) do
          commissioning_document = described_class.new(data_request: data_request)
          commissioning_document.template_name = template_type
          number = offender_sar_case.number
          expect(commissioning_document.filename).to eq "Day1_HMPS_#{number}_Robert-Badson_20221027T0920.docx"
        end
      end
    end
  end

  describe 'setting mime type' do
    it 'sets the mime type as expected' do
      expect(subject.mime_type).to eq :docx
    end
  end
end
