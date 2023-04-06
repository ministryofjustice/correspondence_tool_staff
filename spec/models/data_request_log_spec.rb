require 'rails_helper'

RSpec.describe DataRequestLog, type: :model do
  describe '#create' do
    context 'with valid params' do
      subject(:data_request_log) {
        described_class.new(
          data_request: build_stubbed(:data_request),
          user: build_stubbed(:user),
          date_received: Date.current,
          num_pages: 21,
        )
      }

      it { should be_valid }
    end
  end

  describe '#validate_date_received?' do
    let(:data_request_log) { build_stubbed :data_request_log, :received }
    subject { data_request_log.send(:validate_date_received?) }

    it { should eq false }
    it { expect(data_request_log).to be_valid }

    it 'is false when date_received is not set' do
      data_request_log.date_received = nil
      expect(subject).to be false
    end

    it 'sets the error message when invalid' do
      data_request_log.date_received = Date.today + 1.day

      expect(subject).to be true
      expect(data_request_log.errors[:date_received]).to eq ['cannot be in the future']
    end
  end

  describe 'validation' do
    let(:data_request_log) { build_stubbed :data_request_log, :received }

    it 'ensure date_received is in the past' do
      data_request_log.date_received = Date.today + 1.day
      expect(data_request_log.valid?).to be false

      data_request_log.date_received = Date.today
      expect(data_request_log.valid?).to be true

      data_request_log.date_received = Date.today - 1.day
      expect(data_request_log.valid?).to be true
    end

    it 'ensures num_pages is a positive value only' do
      data_request_log.num_pages = -10
      expect(data_request_log.valid?).to be false

      data_request_log.num_pages = 6.5
      expect(data_request_log.valid?).to be false
    end
  end
end
