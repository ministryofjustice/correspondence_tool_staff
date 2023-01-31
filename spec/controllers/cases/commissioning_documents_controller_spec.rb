require 'rails_helper'

RSpec.describe Cases::CommissioningDocumentsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request) do
    create(
      :data_request,
      offender_sar_case: offender_sar_case,
      cached_num_pages: 10,
      completed: true,
      cached_date_received: Date.yesterday
    )
  end
  let(:commissioning_document) { create(:commissioning_document, data_request: data_request) }

  let(:params) do
    {
      case_id: data_request.case_id,
      data_request_id: data_request.id,
    }
  end

  before do
    sign_in manager
  end

  describe '#new' do
    before do
      get :new, params: params
    end

    it 'sets @case' do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it 'sets @data_request' do
      expect(assigns(:data_request)).to eq data_request
    end
  end

  describe '#create' do
    context 'valid params' do
      let(:params) do
        {
          case_id: data_request.case_id,
          data_request_id: data_request.id,
          commissioning_document: {
            template_name: 'prison'
          }
        }
      end

      it 'creates a commissioning_document' do
        expect {
          post :create, params: params
        }.to change {
          CommissioningDocument.count
        }.by 1
      end

      it 'redirects to data request page' do
        post :create, params: params
        expect(response).to redirect_to(case_data_request_path(offender_sar_case, data_request))
      end
    end

    context 'invalid params' do
      let(:params) do
        {
          case_id: data_request.case_id,
          data_request_id: data_request.id,
          commissioning_document: {
            template_name: ''
          }
        }
      end

      it 'creates a commissioning_document' do
        post :create, params: params
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#update' do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: data_request.case_id,
        data_request_id: data_request.id,
        commissioning_document: {
          template_name: 'probation'
        }
      }
    end

    it 'updates a commissioning_document' do
      expect {
        patch :update, params: params
      }.to change {
        commissioning_document.reload.template_name
      }.to 'probation'
    end

    it 'redirects to data request page' do
      patch :update, params: params
      expect(response).to redirect_to(case_data_request_path(offender_sar_case, data_request))
    end
  end

  describe "#download" do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: data_request.case_id,
        data_request_id: data_request.id,
      }
    end

    it "downloads the commissioning document" do
      get :download, params: params
      expect(response.headers['Content-Disposition']).to match(/filename=\".*docx\"/)
    end
  end
end
