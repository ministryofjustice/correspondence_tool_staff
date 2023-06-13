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

    it 'builds @data_request' do
      data_request = assigns(:data_request)
      expect(data_request).to be_a DataRequest
    end
  end

  describe '#create' do
    context 'with valid params' do
      let(:params) {
        {
          data_request: {
            location: 'Wormwood Scrubs',
            request_type: 'all_prison_records',
            date_requested_dd: "15",
            date_requested_mm: "8",
            date_requested_yyyy: "2020",
          },
          case_id: offender_sar_case.id,
        }
      }

      it 'creates a new DataRequest' do
        expect { post :create, params: params }
          .to change(DataRequest.all, :size).by 1
        expect(response).to redirect_to case_path(offender_sar_case)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) {
        {
          data_request: {
            location: '',
            request_type: 'all_prison_records',
            date_requested_dd: "15",
            date_requested_mm: "8",
            date_requested_yyyy: "2020",
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
  end

  describe '#show' do
    let(:data_request) {
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Date.yesterday
      )
    }

    let(:params) {
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    }

    it 'loads the correct data_request' do
      get :show, params: params

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Date.yesterday
    end
  end

  describe '#edit' do
    let(:data_request) {
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Date.yesterday
      )
    }

    let(:params) {
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    }

    it 'builds a new data_request with last received values' do
      get :edit, params: params

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Date.yesterday
    end
  end

  describe '#update' do
    let(:data_request) {
      create(:data_request, offender_sar_case: offender_sar_case)
    }

    context 'with valid params' do
      let(:params) {
        {
          data_request: {
            cached_num_pages: 2,
            location: 'HMP Brixton',
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

      it 'permits num_pages to be updated' do
        expect(controller.send(:update_params).key?(:cached_num_pages)).to be true
      end
    end

    context 'with invalid params' do
      let(:params) {
        {
          data_request: {
            id: data_request.id,
            cached_num_pages: -10,
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
          data_request: {
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

      expect { delete :destroy, params: { case_id: offender_sar_case.id, id: data_request.id } }
        .to raise_error NotImplementedError, 'Data request delete unavailable'
    end
  end

  describe '#send_email' do
    let(:data_request) {
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Date.yesterday,
        commissioning_document: commissioning_document
      )
    }
    let(:params) {
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    }
    let(:commissioning_document) { create(:commissioning_document, template_name: template_name) }

    context 'probation document selected' do
      let(:template_name) { 'probation' }
      it 'routes to the send_email branston probation page' do
        get :send_email, params: params
        expect(response).to render_template(:probation_send_email)
      end
    end

    context 'non-probation document' do
      let(:template_name) { 'prison' }
      it 'routes to the send_email confirmation page' do
        get :send_email, params: params
        expect(response).to render_template(:send_email)
      end
    end
  end
end
