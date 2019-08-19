require 'rails_helper'

describe DataRequestService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_attributes) {
    {
      '0' => { location: 'The Clinic', data: 'Lots of paper please' },
      '1' => { location: 'The House', data: 'More paper please' },
      '2' => { location: 'A Prison', data: 'Less paper please' },
      '3' => { location: 'The LA', data: 'All your paper please' }
    }
  }
  let(:service) {
    DataRequestService.new(
      kase: offender_sar_case,
      user: user,
      data_requests: data_request_attributes
    )
  }

  describe '#initialize' do
    it 'requires a case, user and 0 or more data request fields' do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.instance_variable_get(:@data_requests)).to eq data_request_attributes
    end

    # No restriction on case type as managed by model
    it 'ignores case type' do
      new_service = described_class.new(
        kase: create(:foi_case),
        user: user,
        data_requests: data_request_attributes
      )

      expect(new_service).to be_instance_of described_class
    end
  end

  describe '#call' do
    context 'on success' do
      it 'saves DataRequest and changes case status' do
        expect(offender_sar_case.current_state).to eq 'data_to_be_requested'
        expect { service.call }.to change(DataRequest.all, :size).by(4)
        expect(service.result).to eq :ok
        expect(offender_sar_case.current_state).to eq 'waiting_for_data'
      end
    end

    context 'on failure' do
      it 'does not save DataRequest' do
        data_requests = service.instance_variable_get(:@data_requests)
        data_requests['0'][:location] = nil

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.result).to eq :error
        expect(service.case.errors.size).to be > 0
      end

      it 'only recovers from ActiveRecord exceptions' do
        class FakeError < ArgumentError; end

        allow_any_instance_of(Case::Base).to receive(:save!).and_raise(FakeError)
        expect { service.call }.to raise_error FakeError
      end
    end
  end
end


