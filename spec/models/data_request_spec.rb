require 'rails_helper'

RSpec.describe DataRequest, type: :model do
  describe '#create' do
    context 'with valid params' do
      subject(:data_request) {
        described_class.new(
          offender_sar_case: build(:offender_sar_case),
          user: build(:user),
          location: 'X' * 500, # Max length
          request_type: 'all_prison_records',
          request_type_note: '',
          date_requested: Date.current
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

      it 'uses supplied date received if present' do
        new_data_request = data_request.clone
        new_data_request.cached_date_received = Date.new(2021, 8, 9)
        new_data_request.save!
        expect(new_data_request.cached_date_received).to eq Date.new(2021, 8, 9)
      end

      it 'defaults to in progress' do
        expect(subject.completed).to eq false
        expect(subject.status).to eq 'In progress'
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

    context 'when request_type is other' do
      subject(:data_request) { build(:data_request, request_type: 'other', request_type_note: nil) }

      it 'ensures the note is present' do
        expect(subject).not_to be_valid
        expect(subject.errors[:request_type_note]).to eq ["can't be blank"]
      end
    end

    context 'when both from and to date is set' do
      subject(:data_request) { build(:data_request, date_from: 1.year.ago, date_to: 2.years.ago)}

      it 'ensures the to date is after the from date' do
        expect(subject).not_to be_valid
        expect(subject.errors[:date_from]).to eq ['cannot be later than date to']
      end
    end

    context 'with note' do
      subject(:data_request) { build :data_request, :other }

      it { should be_valid }
      it 'has a note' do
        expect(data_request.request_type_note).to eq 'Lorem ipsum'
      end
    end

    context 'with date range' do
      subject(:data_request) { build :data_request, :with_date_range }

      it { should be_valid }
      it 'has date from and to' do
        expect(data_request.date_from).to eq Date.new(2018, 01, 01)
        expect(data_request.date_to).to eq Date.new(2018, 12, 31)
      end
    end

    context 'with date range' do
      subject(:data_request) { build :data_request, :with_date_from }

      it { should be_valid }
    end

    context 'with date range' do
      subject(:data_request) { build :data_request, :with_date_to }

      it { should be_valid }
    end
  end

  describe '#request_type' do
    context 'valid values' do
      it 'does not error' do
        expect(build(:data_request, request_type: 'all_prison_records')).to be_valid
        expect(build(:data_request, request_type: 'security_records')).to be_valid
        expect(build(:data_request, request_type: 'nomis_records')).to be_valid
        expect(build(:data_request, request_type: 'nomis_other')).to be_valid
        expect(build(:data_request, request_type: 'nomis_contact_logs')).to be_valid
        expect(build(:data_request, request_type: 'probation_records')).to be_valid
        expect(build(:data_request, request_type: 'cctv_and_bwcf')).to be_valid
        expect(build(:data_request, request_type: 'telephone_recordings')).to be_valid
        expect(build(:data_request, request_type: 'probation_archive')).to be_valid
        expect(build(:data_request, request_type: 'mappa')).to be_valid
        expect(build(:data_request, request_type: 'pdp')).to be_valid
        expect(build(:data_request, request_type: 'court')).to be_valid
        expect(build(:data_request, request_type: 'other', request_type_note: 'test')).to be_valid
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

  describe '#status' do
    context 'when data request is in progress' do
      let!(:data_request) { build(:data_request) }
      it 'returns completed' do
        expect(data_request.status).to eq 'In progress'
      end
    end
    context 'when data request is completed' do
      let!(:data_request) { build(:data_request, :completed) }
      it 'returns completed' do
        expect(data_request.status).to eq 'Completed'
      end
    end
  end

  describe 'scope completed' do
    let!(:data_request_in_progress) { create(:data_request) }
    let!(:data_request_completed) { create(:data_request, :completed) }
    it 'returns completed data requests' do
      expect(DataRequest.completed).to match_array [data_request_completed]
      expect(DataRequest.completed).not_to include data_request_in_progress
    end
  end

  describe 'scope in_progress' do
    let!(:data_request_in_progress) { create(:data_request) }
    let!(:data_request_completed) { create(:data_request, :completed) }
    it 'returns in progress data requests' do
      expect(DataRequest.in_progress).to match_array [data_request_in_progress]
      expect(DataRequest.in_progress).not_to include data_request_completed
    end
  end

  describe '#request_dates_either_present?' do
    context 'when no request dates available' do
      subject(:data_request) { build :data_request }
      it { expect(subject.request_dates_either_present?).to eq false }
    end

    context 'when from request date available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }
      it { expect(subject.request_dates_either_present?).to eq true }
    end

    context 'when to request date available' do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }
      it { expect(subject.request_dates_either_present?).to eq true }
    end

    context 'when both request dates available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }
      it { expect(subject.request_dates_either_present?).to eq true }
    end
  end

  describe '#request_dates_both_present?' do
    context 'when no request dates available' do
      subject(:data_request) { build :data_request }
      it { expect(subject.request_dates_both_present?).to eq false }
    end
    context 'when one request date available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }
      it { expect(subject.request_dates_both_present?).to eq false }
    end
    context 'when both request dates available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }
      it { expect(subject.request_dates_both_present?).to eq true }
    end
  end

  describe '#request_date_from_only?' do
    context 'when no request dates available' do
      subject(:data_request) { build :data_request }
      it { expect(subject.request_date_from_only?).to eq false }
    end

    context 'when from request date available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }
      it { expect(subject.request_date_from_only?).to eq true }
    end

    context 'when to request date available' do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }
      it { expect(subject.request_date_from_only?).to eq false }
    end

    context 'when both request dates available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }
      it { expect(subject.request_date_from_only?).to eq false }
    end
  end

  describe '#request_date_to_only?' do
    context 'when no request dates available' do
      subject(:data_request) { build :data_request }
      it { expect(subject.request_date_to_only?).to eq false }
    end

    context 'when from request date available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }
      it { expect(subject.request_date_to_only?).to eq false }
    end

    context 'when to request date available' do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }
      it { expect(subject.request_date_to_only?).to eq true }
    end

    context 'when both request dates available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }
      it { expect(subject.request_date_to_only?).to eq false }
    end
  end

  describe '#request_dates_absent?' do
    context 'when no request dates available' do
      subject(:data_request) { build :data_request }
      it { expect(subject.request_dates_absent?).to eq true }
    end
    context 'when from request date available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15) }
      it { expect(subject.request_dates_absent?).to eq false }
    end

    context 'when to request date available' do
      subject(:data_request) { build :data_request, date_to: Date.new(2019, 8, 15) }
      it { expect(subject.request_dates_absent?).to eq false }
    end

    context 'when both request dates available' do
      subject(:data_request) { build :data_request, date_from: Date.new(2019, 8, 15), date_to: Date.new(2020, 8, 15) }
      it { expect(subject.request_dates_absent?).to eq false }
    end
  end
end
