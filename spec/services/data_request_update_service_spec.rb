require 'rails_helper'

describe DataRequestUpdateService do
  let(:user) { create :user }
  let(:data_request) {
    create(
      :data_request,
      location: 'HMP Leicester',
      request_type: 'A list of all evening meals'
    )
  }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:params) {
    {
      num_pages: 21,
      date_received_dd: '1', date_received_mm: '12', date_received_yyyy: '1992',
    }
  }
  let(:service) {
    described_class.new(
      user: user,
      data_request: data_request,
      params: params,
    )
  }

  describe '#initialize' do
    it 'requires a user. data request and fields to update' do
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.data_request).to eq data_request
      expect(service.instance_variable_get(:@params)).to eq params
    end
  end

  describe '#call' do
    context 'on success' do
      let(:service) {
        described_class.new(
          user: user,
          data_request: data_request,
          params: params,
        )
      }

      before do
        expect(data_request.cached_num_pages).to eq 0
        expect(data_request.cached_date_received).to be_nil
      end

      it 'creates a new case transition (history) entry' do
        expect { service.call }.to change(CaseTransition.all, :size).by(1)
        expect(CaseTransition.last.event).to eq 'add_data_received'
      end

      it 'creates a new log entry' do
        expect { service.call }.to change(DataRequestLog.all, :size).by(1)
      end

      it 'updates the data request with the same values as a new DataRequestLog' do
        service.call
        log = DataRequestLog.last

        # De-normalised values should match the DataRequestLog values
        expect(data_request.cached_num_pages).to eq 21
        expect(data_request.cached_date_received.strftime('%F')).to eq '1992-12-01'

        expect(log.num_pages).to eq data_request.cached_num_pages
        expect(log.date_received).to eq data_request.cached_date_received
        expect(log.user).to eq user
      end
    end

    context 'on failure' do
      it 'does not save DataRequest when validation errors' do
        bad_params = params.clone
        bad_params.merge!(num_pages: -20)
        service.instance_variable_set(:@params, bad_params)
        previous_cached_num_pages = data_request.cached_num_pages
        previous_cached_date_received = data_request.cached_date_received

        expect { service.call }.to change(CaseTransition.all, :size).by(0)
        expect { service.call }.to change(DataRequestLog.all, :size).by(0)
        expect(service.data_request.errors.size).to be > 0
        expect(service.result).to eq :error

        expect(data_request.reload.cached_num_pages).to eq previous_cached_num_pages
        expect(data_request.reload.cached_date_received).to eq previous_cached_date_received

      end

      it 'does not create DataRequestLog or CaseHistory when no data' do
        service.instance_variable_set(:@params, {})

        expect { service.call }.to change(CaseTransition.all, :size).by(0)
        expect { service.call }.to change(DataRequestLog.all, :size).by(0)
        expect(service.result).to eq :error
      end

      it 'only recovers from ActiveRecord exceptions' do
        class FakeError < ArgumentError; end

        allow_any_instance_of(DataRequest).to receive(:save!).and_raise(FakeError)
        expect { service.call }.to raise_error FakeError
      end
    end
  end

  describe '#log_message' do
    it 'creates a human readable case history message' do
      service.call
      expect(CaseTransition.last.message).to eq "A list of all evening meals, HMP Leicester on 1992-12-01: changed from 0 pages to 21 pages"
    end

    it 'uses the singular word `page` when 1 page updated' do
      service.instance_variable_set(:@params, params.merge({ num_pages: 1 }))
      service.call
      expect(CaseTransition.last.message).to eq "A list of all evening meals, HMP Leicester on 1992-12-01: changed from 0 pages to 1 page"
    end
  end

  describe '#unchanged?' do
    let!(:data_request) {
      create(
        :data_request,
        cached_num_pages: 24,
        cached_date_received: Date.new(2018, 1, 3)
      )
    }

    before do
      service.instance_variable_set(:@data_request, data_request)
    end

    it 'is true when new values are same as old values' do
      new_data_request_log = data_request.logs.build(
        user: user,
        num_pages: 24,
        date_received: Date.new(2018, 1, 3),
      )

      expect(service.send(:unchanged?, new_data_request_log)).to eq true
    end

    it 'is false when number of pages is updated' do
      new_data_request_log = data_request.logs.build(
        user: user,
        num_pages: 42, # Changed
        date_received: Date.new(2018, 1, 3) # Same
      )

      expect(service.send(:unchanged?, new_data_request_log)).to eq false
    end

    it 'is false when date received is updated' do
      new_data_request_log = data_request.logs.build(
        user: user,
        num_pages: 24, # Same
        date_received: Date.new(1915, 12, 25) # Changed
      )

      expect(service.send(:unchanged?, new_data_request_log)).to eq false
    end
  end
end
