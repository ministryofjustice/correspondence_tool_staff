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
  let(:commissioning_document) { create(:commissioning_document, data_request: data_request, template_name: 'probation') }

  let(:params) do
    {
      case_id: data_request.case_id,
      data_request_id: data_request.id,
    }
  end

  let(:kase) {
    create(
      :offender_sar_case,
      subject_full_name: 'Robert Badson',
    )
  }

  before do
    sign_in manager
  end

  # context 'show probation_send_email' do
  #   let(:params) {
  #     {
  #       data_request: {
  #         location: 'Wormwood Scrubs',
  #         request_type: 'probation_records',
  #         date_requested_dd: "15",
  #         date_requested_mm: "8",
  #         date_requested_yyyy: "2020",
  #       },
  #       case_id: offender_sar_case.id,
  #     }
  #   }
  #
  #   it 'renders the branston send email URL' do
  #     debugger
  #     post :create, params: params
  #     expect(response).to redirect_to send_email_case_data_request_path(offender_sar_case, data_request)
  #   end
  # end
  context 'valid params' do
    let(:params) do
      {
        case_id: data_request.case_id,
        data_request_id: data_request.id,
        commissioning_document: {
          template_name: 'probation'
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
      expect(response).to redirect_to(send_email_case_data_request_path(offender_sar_case, data_request))
    end
  end
end
