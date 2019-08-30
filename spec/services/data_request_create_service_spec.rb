require 'rails_helper'

describe DataRequestCreateService do
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
    described_class.new(
      kase: offender_sar_case,
      user: user,
      data_requests: data_request_attributes
    )
  }

  describe '#initialize' do
    it 'requires a case, user and 0 or more data request fields' do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.instance_variable_get(:@new_data_requests)).to respond_to :each
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
        expect(offender_sar_case.current_state).to eq 'waiting_for_data'

        # @todo CaseTransition Added

        expect(service.result).to eq :ok
      end

      it 'skips any blank pairs of location/data' do
        params = data_request_attributes.clone
        params.merge!({
          '0' => { location: nil, data: '              ' },
          '2' => { location: '                  ', data: nil },
        })

        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_requests: params
        )

        expect { service.call }.to change(DataRequest.all, :size).by(2)
        expect(service.result).to be :ok
      end
    end

    context 'on failure' do
      it 'does not save DataRequest when validation errors' do
        params = data_request_attributes.clone
        params.merge!({ '0' => { location: 'too', data: 'few' }})

        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_requests: params
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.case.errors.size).to be > 0
        expect(service.result).to eq :error
      end

      it 'does not save DataRequest when nothing to process' do
        service = described_class.new(
          kase: offender_sar_case,
          user: user,
          data_requests: {}
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.result).to eq :unprocessed
      end

      it 'only recovers from ActiveRecord exceptions' do
        class FakeError < ArgumentError; end

        allow_any_instance_of(Case::Base).to receive(:save!).and_raise(FakeError)
        expect { service.call }.to raise_error FakeError
      end
    end
  end

  describe '#process?' do
    it 'returns true only when one or more of the attributes is present' do
      test_cases = [
        { expect: false, location: '', data: '' },
        { expect: false, location: '       ', data: '' },
        { expect: false, location: '       ', data: '     ' },
        { expect: false, location: nil, data: '      ' },
        { expect: false, location: '        ', data: nil },
        { expect: true,  location: nil, data: ' Some Data      ' },
        { expect: true,  location: ' A Location       ', data: nil },
        { expect: true,  location: 'A Location        ', data: '  Some dat a' },
      ]

      test_cases.each do |params|
        expect(service.process?(**params.slice(:location, :data))).to eq params[:expect]
      end
    end


    it 'returns true when location and data are both present' do
      result = service.process?(
        location: ' The Location with spaces    ',
        data: ' The Data with spaces'
      )

      expect(result).to be true
    end

    it 'returns true when either location and data present' do
      result = service.process?(
        location: ' The Location with spaces    ',
        data: nil
      )
      expect(result).to be true

      result = service.process?(
        location: nil,
        data: 'This is some data  '
      )

      expect(result).to be true
    end
  end

  describe '#build_data_requests' do
    it 'returns empty array if the case is unsupported by data requests' do
      new_service = described_class.new(
        kase: create(:foi_case),
        user: user,
        data_requests: data_request_attributes
      )

      expect(new_service.build_data_requests(data_request_attributes)).to eq []
    end

    it 'generates a list of DataRequest instances' do
      new_data_requests = service.build_data_requests(data_request_attributes)

      expect(new_data_requests).to respond_to :each
      expect(
        new_data_requests.all? do |data_request|
          data_request.kind_of? DataRequest
        end
      ).to be true

      expect(service.case.data_requests.size).to be > 0
    end

    it 'generates an empty list when no DataRequest is built' do
      params = {
        '0' => { location: nil, data: '              ' },
        '1' => { location: '                  ', data: nil },
      }

      expect(service.build_data_requests(params)).to eq []
    end
  end
end


