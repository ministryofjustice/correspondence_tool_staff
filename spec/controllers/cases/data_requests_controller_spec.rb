require 'rails_helper'

RSpec.describe Cases::DataRequestsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }

  before do
    sign_in manager
  end

  describe '#new' do
    before do
      get :new, params: { case_id: offender_sar_case.id }
    end

    it 'sets @case' do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it 'builds 3 @data_requests' do
      data_requests = assigns(:data_requests)
      data_requests.each { |data_request| expect(data_request).to be_a DataRequest }
      expect(data_requests.size).to eq 3
    end
  end

  describe '#create' do
    context 'with valid params' do
      let(:params) {
        {
          case: {
            data_requests_attributes: {
              '0': {
                location: 'Wormwood Scrubs',
                request_type: 'Report on Mickey Spous 1972',
              },
              '1': {
                location: 'Super Max 1',
                request_type: 'Full list of meals served',
              },
            },
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'creates a new DataRequest' do
        expect { post :create, params: params }
          .to change(DataRequest.all, :size).by 2
        expect(response).to redirect_to case_path(offender_sar_case)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) {
        {
          case: {
            data_requests_attributes: {
              '0': {
                location: 'A Location',
                request_type: '',
              },
            },
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'does not create a new DataRequest' do
        expect { post :create, params: invalid_params }
          .to change(DataRequest.all, :size).by 0
        expect(response).to render_template(:new)
      end
    end

    context 'with blank params' do
      let(:blank_params) {
        {
          case: {
            data_requests_attributes: {
              '0': {
                location: '         ',
                request_type: nil,
              },
            },
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'does not create a new DataRequest' do
        expect { post :create, params: blank_params }
          .to change(DataRequest.all, :size).by 0
        expect(response).to redirect_to new_case_data_request_path(offender_sar_case)
      end
    end

    context 'with unknown service result' do
      let(:params) {
        {
          case: {
            data_requests_attributes: {
              '0': {
                location: 'Wormwood Scrubs',
                request_type: 'Report on Mickey Spous 1972',
              },
            },
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'raises an ArgumentError' do
        allow_any_instance_of(DataRequestCreateService)
          .to receive(:result).and_return(:bogus_result!)

        expect { post :create, params: params }
          .to raise_error ArgumentError, match(/Unknown result/)
      end
    end
  end

  describe '#edit' do
    let(:data_request) {
      create(
        :data_request,
        cached_num_pages: 10,
        cached_date_received: Date.yesterday
      )
    }

    let(:params) {
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    }

    it 'builds a new data_request_log with last received values' do
      get :edit, params: params

      expect(assigns(:data_request_log).new_record?).to eq true
      expect(assigns(:data_request_log).num_pages).to eq 10
      expect(assigns(:data_request_log).date_received).to eq Date.yesterday
    end
  end

  describe '#update' do
    let(:data_request) {
      create(:data_request, offender_sar_case: offender_sar_case)
    }

    context 'with valid params' do
      let(:params) {
        {
          data_request_log: {
            date_received_dd: 2,
            date_received_mm: 8,
            date_received_yyyy: 2012,
            num_pages: 2,
            location: 'not permitted during update',
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      }

      before do
        patch :update, params: params
      end

      it 'updates the DataRequest' do
        expect(response).to redirect_to case_path(data_request.case_id)
        expect(controller).to set_flash[:notice]
      end

      it 'only permits date_received and num_pages to be updated' do
        expect(controller.send(:update_params).key?(:num_pages)).to be true
        expect(controller.send(:update_params).key?(:date_received_dd)).to be true
        expect(controller.send(:update_params).key?(:location)).to be false
      end
    end

    context 'with invalid params' do
      let(:params) {
        {
          data_request_log: {
            id: data_request.id,
            date_received_dd: 12,
            date_received_mm: 13,
            date_received_yyyy: 2129,
            num_pages: -10,
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      }

      it 'does not update the DataRequest' do
        patch :update, params: params
        expect(response).to render_template(:edit)
      end
    end

    context 'with unknown service result' do
      let(:params) {
        {
          data_request_log: {
            id: data_request.id,
            date_received_dd: 2,
            date_received_mm: 8,
            date_received_yyyy: 2012,
            num_pages: 2,
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      }

      it 'raises an ArgumentError' do
        allow_any_instance_of(DataRequestUpdateService)
          .to receive(:result).and_return(:bogus_result!)

        expect { patch :update, params: params }
          .to raise_error ArgumentError, match(/Unknown result/)
      end
    end
  end

  describe '#destroy' do
    it 'is not implemented' do
      data_request = create :data_request, offender_sar_case: offender_sar_case

      expect { delete :destroy, params: { case_id: offender_sar_case.id, id: data_request.id }}
        .to raise_error NotImplementedError, 'Data request delete unavailable'
    end
  end
end
