require 'rails_helper'

describe DataRequestUpdateService do
  let(:user) { create :user }
  let(:data_request) {
    create(
      :data_request,
      location: 'HMP Leicester',
      request_type: 'offender'
    )
  }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:params) {
    {
      location: 'HMP Brixton',
      request_type: 'offender',
      request_type_note: 'Lorem ipsum',
      date_from_dd: "15",
      date_from_mm: "8",
      date_from_yyyy: "2018",
      date_to_dd: "15",
      date_to_mm: "8",
      date_to_yyyy: "2019",
      cached_num_pages: 21,
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

      it 'updates the data request values' do
        service.call
        request = service.data_request

        # De-normalised values should match the DataRequestLog values
        expect(request.cached_num_pages).to eq 21
      end
    end

    context 'on failure' do
      it 'does not save DataRequest when validation errors' do
        bad_params = params.clone
        bad_params.merge!(cached_num_pages: -20)
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
      expect(CaseTransition.last.message).to eq "offender, HMP Brixton on #{Date.current.strftime('%F')}: changed from 0 pages to 21 pages"
    end

    it 'uses the singular word `page` when 1 page updated' do
      service.instance_variable_set(:@params, params.merge({ cached_num_pages: 1 }))
      service.call
      expect(CaseTransition.last.message).to eq "offender, HMP Brixton on #{Date.current.strftime('%F')}: changed from 0 pages to 1 page"
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
  end
end
