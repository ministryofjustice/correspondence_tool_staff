require 'rails_helper'

describe CreateOverturnedICOCaseService do

  describe '.new' do
    context 'id of non existent case' do
      it 'raises' do
        expect {
          described_class.new(9123456)
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe '#call' do

    context 'original ico appeal case type is  not ICO' do
      let(:service)                 { described_class.new(original_ico_appeal.id) }
      let(:original_ico_appeal)     { create :case }
      let(:original_case)           { create :case }


      before(:each) do
        allow(original_ico_appeal).to receive(:original_case).and_return(original_case)
        service.call
      end

      it 'adds an error to the original case' do
        expect(service.original_ico_appeal.errors[:base]).to eq ['Invalid ICO appeal case type']
      end

      it 'sets the error flag' do
        expect(service.error?).to be true
      end
    end

    context 'original ico appeal case type is Case::ICO::SAR' do

      let(:original_ico_appeal)     { create :ico_sar_case }
      let(:original_case)           { create :sar_case }
      let(:service)                 { described_class.new(original_ico_appeal.id) }

      before(:each) do
        allow_any_instance_of(Case::ICO::SAR).to receive(:original_case).and_return(original_case)
        service.call
      end

      it 'sets the new overturned case to be a Case::OverturnedICO::SAR' do
        expect(service.overturned_ico_case).to be_instance_of(Case::OverturnedICO::SAR)
      end

      it 'is success' do
        expect(service.success?).to be true
      end
    end

    context 'original case type is Case::ICO::FOI' do
      let(:original_ico_appeal)     { create :ico_foi_case }
      let(:original_case)           { create :foi_case }
      let(:service)                 { described_class.new(original_ico_appeal.id) }

      before(:each) do
        allow_any_instance_of(Case::ICO::FOI).to receive(:original_case).and_return(original_case)
        service.call
      end

      it 'sets the new overturned case to be a Case::OverturnedICO::SAR' do
        expect(service.overturned_ico_case).to be_instance_of(Case::OverturnedICO::FOI)
      end

      it 'is success' do
        expect(service.success?).to be true
      end
    end
  end

end
