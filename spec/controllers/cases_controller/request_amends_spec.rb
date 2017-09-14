require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:pending_private_clearance_case) { create :pending_private_clearance_case, private_officer: private_officer }
  let(:private_officer)                { create :private_officer }

  describe 'GET request_amends' do
    before do
      sign_in private_officer
    end

    it 'authorizes' do
      expect {
        get :request_amends, params: { id: pending_private_clearance_case.id }
      } .to require_permission(:request_amends?)
              .with_args(private_officer, pending_private_clearance_case)
    end

    it 'instantiates NextStepInfo object' do
      nsi = instance_double(NextStepInfo)
      allow(NextStepInfo).to receive(:new).with(any_args).and_return(nsi)

      get :request_amends, params: { id: pending_private_clearance_case }

      expect(assigns(:next_step_info)).to eq nsi
      expect(NextStepInfo).to have_received(:new).with(
                                pending_private_clearance_case,
                                'request-amends',
                                private_officer
                              )
    end

    it 'renders the request_amends template' do
      get :request_amends, params: { id: pending_private_clearance_case }
      expect(response).to have_rendered('cases/request_amends')
    end
  end
end
