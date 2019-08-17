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

    it 'sets @data_request' do
      expect(assigns(:data_request)).to be_new_record
    end
  end

  describe '#create' do
    context 'with valid params' do
      let(:params) {
        {
          data_request: {
            location: 'Wormwood Scrubs',
            data: 'Report on Mickey Spous 1972',
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'creates a new DataRequest' do
        expect { post :create, params: params }
          .to change(DataRequest.all, :size).by 1
      end
    end

    context 'with invalid params' do
      let(:invalid_params) {
        {
          data_request: {
            location: '',
            data: '',
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'does not create a new DataRequest' do
        expect { post :create, params: invalid_params }
          .to change(DataRequest.all, :size).by 0
      end

      it 'renders new' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end
end
