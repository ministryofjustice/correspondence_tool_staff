require 'rails_helper'

RSpec.describe Cases::DataRequestsController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
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

    it 'builds 3 @case.data_requests' do
      kase = assigns(:case)
      kase.data_requests.each { |data_request| expect(data_request).to be_new_record }
      expect(kase.data_requests.size).to eq 3
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
                data: 'Report on Mickey Spous 1972',
              },
              '1': {
                location: 'Super Max 1',
                data: 'Full list of meals served',
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
                data: '',
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
                data: nil,
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
  end
end
