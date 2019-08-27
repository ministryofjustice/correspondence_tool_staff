require 'rails_helper'

RSpec.describe DataRequest, type: :model do
  describe '#create' do
    context 'with valid params' do
      subject(:data_request) {
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build(:user),
          location: 'X' * 500, # Max length
          data: 'Please supply a huge list of misdemeanours by Miers Porgan'
        )
      }

      it { should be_valid }

      it 'has 0 num_pages by default' do
        expect(data_request.num_pages).to eq 0
      end
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

      it 'ensures num_pages is a positive value only' do
        data_request.num_pages = -10
        expect(data_request.valid?).to be false

        data_request.num_pages = 6.5
        expect(data_request.valid?).to be false
      end

      it 'ensure date_received is in the past' do
        data_request.date_received = Date.today + 1.day
        expect(data_request.valid?).to be false

        data_request.date_received = Date.today
        expect(data_request.valid?).to be true

        data_request.date_received = Date.today - 1.day
        expect(data_request.valid?).to be true
      end
    end
  end

  describe '#case' do
    subject(:data_request) { build :data_request }

    it { should be_valid }

    it 'is restricted to Offender SAR at present' do
      expect { data_request.offender_sar_case = build(:foi_case) }
        .to raise_error ActiveRecord::AssociationTypeMismatch
    end
  end

  describe '#clean_attributes' do
    subject(:data_request) { build :data_request }

    it 'ensures string attributes do not have leading/trailing spaces' do
      data_request.data = '    So much space '
      data_request.location = '  The location'

      data_request.send(:clean_attributes)

      expect(data_request.data).to eq 'So much space'
      expect(data_request.location).to eq 'The location'
    end

    it 'ensures string attributes have the first letter capitalised' do
      data_request.data = 'some DaTa'
      data_request.location = 'leicester'

      data_request.send(:clean_attributes)

      expect(data_request.data).to eq 'Some DaTa'
      expect(data_request.location).to eq 'Leicester'
    end

    it 'is executed before validating' do
      data_request.location = '             ' # Meets min string length req
      expect(data_request.valid?).to be false
    end
  end

  describe '#validate_date_received?' do
    subject(:data_request) { build :data_request }

    it { should be_valid }

    it 'is false when date_received is not set' do
      data_request.date_received = nil
      expect(data_request.send(:validate_date_received?)).to be false
    end

    it 'sets the error message when invalid' do
      data_request.date_received = Date.today + 1.day
      expect(data_request.send(:validate_date_received?)).to be true
      expect(data_request.errors[:date_received]).to eq ['cannot be in the future']
    end
  end
end
