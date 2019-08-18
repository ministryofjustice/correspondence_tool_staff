require 'rails_helper'

describe DataRequestService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:params) {{ location: 'London HMP', data: 'Full details for someone' }}
  let(:service) {
    DataRequestService.new(kase: offender_sar_case, user: user, params: params)
  }

  describe '#initialize' do
    it 'requires a case, user and data request params' do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.instance_variable_get(:@location)).to eq params[:location]
      expect(service.instance_variable_get(:@data)).to eq params[:data]
    end

    # No restriction on case type as managed by model
    it 'ignores case type' do
      new_service = described_class.new(
        kase: create(:foi_case),
        user: user,
        params: params
      )

      expect(new_service).to be_instance_of described_class
    end
  end

  describe '#call' do
    context 'on success' do
      it 'saves DataRequest' do
        expect { service.call }.to change(DataRequest.all, :size).by(1)
        expect(service.result).to eq :ok
        expect(service.data_request)
      end
    end

    context 'on failure' do
      it 'saves DataRequest' do
        service.instance_variable_set(:@case, nil)

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.result).to eq :error
        expect(service.data_request).to be_new_record
        expect(service.data_request.errors.size).to be > 0
      end
    end
  end
end


