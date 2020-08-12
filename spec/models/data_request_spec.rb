require 'rails_helper'

RSpec.describe DataRequest, type: :model do
  describe '#create' do
    context 'with valid params' do
      subject(:data_request) {
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build(:user),
          location: 'X' * 500, # Max length
          request_type: 'other',
          request_type_note: 'Here are further clarifications by Miers Porgan'
        )
      }

      it { should be_valid }

      it 'has 0 cached_num_pages by default' do
        expect(data_request.cached_num_pages).to eq 0
      end

      it 'sets date_requested to today by default' do
        data_request.save!
        expect(data_request.date_requested).to eq Date.current
      end

      it 'uses supplied date_requested if present' do
        new_data_request = data_request.clone
        new_data_request.date_requested = Date.new(1992, 7, 11)
        new_data_request.save!
        expect(new_data_request.date_requested).to eq Date.new(1992, 7, 11)
      end
    end

    context 'validation' do
      subject(:data_request) { build :data_request }

      it { should be_valid }

      it 'requires location' do
        invalid_values = ['', ' ', nil]

        invalid_values.each do |bad_location|
          data_request.location = bad_location
          expect(data_request.valid?).to be false
        end

        data_request.location = 'ABCD' * 500 # Exceed max 500 chars
        expect(data_request.valid?).to be false
      end

      it 'requires a request type' do
        invalid_values = ['', ' ', nil]

        invalid_values.each do |bad_data|
          data_request.request_type = bad_data
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

      it 'ensures cached_num_pages is a positive value only' do
        data_request.cached_num_pages = -10
        expect(data_request.valid?).to be false

        data_request.cached_num_pages = 6.5
        expect(data_request.valid?).to be false
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

  describe '#request_type' do
    context 'valid values' do
      it 'does not error' do
        expect(build(:data_request, request_type: 'offender')).to be_valid
        expect(build(:data_request, request_type: 'prison_and_probation_records')).to be_valid
      end
    end

    context 'invalid value' do
      it 'errors' do
        expect {
          build(:data_request, request_type: 'user')
        }.to raise_error ArgumentError
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:data_request, request_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_type]).to eq ["can't be blank"]
      end
    end
  end

  describe '#clean_attributes' do
    subject(:data_request) { build :data_request }

    it 'ensures string attributes do not have leading/trailing spaces' do
      data_request.location = '  The location'
      data_request.send(:clean_attributes)
      expect(data_request.location).to eq 'The location'
    end

    it 'ensures string attributes have the first letter capitalised' do
      data_request.location = 'leicester'
      data_request.send(:clean_attributes)
      expect(data_request.location).to eq 'Leicester'
    end

    it 'is executed before validating' do
      data_request.location = '             ' # Meets min string length req
      expect(data_request.valid?).to be false
    end
  end

  describe '#new_log' do
    subject {
      build(
        :data_request,
        cached_num_pages: 13,
        cached_date_received: Date.new(1982, 3, 1)
      ).new_log
    }

    it { should be_an_instance_of DataRequestLog }
    it { expect(subject.num_pages).to eq 13 }
    it { expect(subject.date_received).to eq Date.new(1982, 3, 1) }
  end
end
