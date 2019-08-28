require 'rails_helper'

describe DataRequestUpdateService do
  let(:user) { create :user }
  let(:data_request) {
    create(
      :data_request,
      location: 'HMP Leicester',
      data: 'A list of all evening meals'
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
        expect(data_request.num_pages).to eq 0
        expect(data_request.date_received).to be_nil
      end

      it 'creates a new case transition (history) entry' do
        expect { service.call }.to change(CaseTransition.all, :size).by(1)
        expect(CaseTransition.last.event).to eq 'add_data_received'
      end

      it 'updates the data request' do
        service.call
        expect(data_request.num_pages).to eq 21
        expect(data_request.date_received.strftime('%F')).to eq '1992-12-01'
      end
    end

    context 'on failure' do
      it 'does not save DataRequest when validation errors' do
        bad_params = params.clone
        bad_params.merge!(num_pages: -20)
        service.instance_variable_set(:@params, bad_params)

        expect { service.call }.to change(CaseTransition.all, :size).by(0)
        expect(service.data_request.errors.size).to be > 0
        expect(service.result).to eq :error
      end

      it 'does not save DataRequest when nothing to process' do
        service.instance_variable_set(:@params, {})

        expect { service.call }.to change(CaseTransition.all, :size).by(0)
        expect(service.result).to eq :unprocessed
      end

      it 'only recovers from ActiveRecord exceptions' do
        class FakeError < ArgumentError; end

        allow_any_instance_of(DataRequest).to receive(:update!).and_raise(FakeError)
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

  describe '#empty_params?' do
    let(:empty_params) {
      {
        num_pages: nil,
        date_received_dd: nil, date_received_mm: '', date_received_yyyy: nil,
      }
    }

    it 'is true when no updatable values given' do
      empty_params = {
        num_pages: nil,
        date_received_dd: nil, date_received_mm: '', date_received_yyyy: nil,
      }
      service.instance_variable_set(:@params, empty_params)

      expect(service.send(:empty_params?)).to eq true
    end

    it 'is false when any one updatable value is given' do
      service.instance_variable_set(:@params, empty_params.merge({ num_pages: 2 }))
      expect(service.send(:empty_params?)).to eq false

      service.instance_variable_set(:@params, empty_params.merge({ date_received_mm: 3 }))
      expect(service.send(:empty_params?)).to eq false
    end
  end
end
