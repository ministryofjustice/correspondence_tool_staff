require 'rails_helper'

RSpec.describe DataRequest, type: :model do
  describe '#create' do
    context 'with valid params' do
      subject(:data_request) {
        described_class.new(
          offender_sar_case: create(:offender_sar_case),
          user: create(:user),
          location: 'X' * 500, # Max length
          data: 'Please supply a huge list of misdemeanours by Miers Porgan'
        )
      }

      it { should be_valid }
    end

    context 'validation' do
      subject(:data_request) { build :data_request }

      it { should be_valid }

      it 'requires location' do
        invalid_values = ['', ' ', nil, '1234']

        invalid_values.each do |bad_location|
          data_request.location = bad_location
          expect(data_request.valid?).to be false
        end

        data_request.location = 'ABCD' * 500 # Exceed max 500 chars
        expect(data_request.valid?).to be false
      end

      it 'requires data' do
        invalid_values = ['', ' ', nil, '1234']

        invalid_values.each do |bad_data|
          data_request.data = bad_data
          expect(data_request.valid?).to be false
        end
      end

      it 'requires a creating user' do
        data_request.user = nil
        expect(data_request.valid?).to be false
      end

      it 'requires a case' do
        data_request.offender_sar_case = nil
        expect(data_request.valid?).to be false
      end
    end
  end

  describe '#case' do
    subject(:data_request) { build :data_request }

    it { should be_valid }

    it 'is restricted to Offender SAR at present' do
      expect { data_request.offender_sar_case = create(:foi_case) }
        .to raise_error ActiveRecord::AssociationTypeMismatch
    end
  end
end
