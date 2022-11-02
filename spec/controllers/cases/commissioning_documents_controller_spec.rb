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
end
