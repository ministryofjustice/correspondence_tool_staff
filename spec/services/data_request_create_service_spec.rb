require 'rails_helper'

describe DataRequestCreateService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_attributes) {
    { location: 'The Clinic', request_type: 'offender' }
  }
  let(:service) {
    described_class.new(
      kase: offender_sar_case,
      user: user,
      data_request: data_request_attributes
    )
  }

  describe '#initialize' do
    it 'requires a case and user' do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
    end

    # No restriction on case type as managed by model
    it 'ignores case type' do
      new_service = described_class.new(
        kase: create(:foi_case),
        user: user,
        data_request: data_request_attributes
      )

      expect(new_service).to be_instance_of described_class
    end
  end

  describe '#call' do
    context 'on success' do
      it 'saves DataRequest and changes case status' do
        expect(offender_sar_case.current_state).to eq 'data_to_be_requested'
        expect { service.call }.to change(DataRequest.all, :size).by(1)
        expect(offender_sar_case.current_state).to eq 'waiting_for_data'

        # @todo CaseTransition Added

        expect(service.result).to eq :ok
      end

      it 'skips any blank pairs of location/data' do
        params = data_request_attributes.clone
        params.merge!({
          '0' => { location: nil, request_type: '              ' },
          '2' => { location: '                  ', request_type: nil },
        })

        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_request: params
        )

        expect { service.call }.to change(DataRequest.all, :size).by(1)
        expect(service.result).to be :ok
      end
    end

    context 'on failure' do
      it 'does not save DataRequest when validation errors' do
        params = data_request_attributes.clone
        params.merge!({ location: 'too' * 500, request_type: 'offender' } )

        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_request: params
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.case.errors.size).to be > 0
        expect(service.result).to eq :error
      end

      it 'does not save DataRequest when nothing to process' do
        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_request: {}
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.result).to eq :error
      end

      it 'only recovers from ActiveRecord exceptions' do
        class FakeError < ArgumentError; end

        allow_any_instance_of(Case::Base).to receive(:save!).and_raise(FakeError)
        expect { service.call }.to raise_error FakeError
      end
    end
  end
end


