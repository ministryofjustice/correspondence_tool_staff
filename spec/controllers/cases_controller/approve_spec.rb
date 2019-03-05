require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:responded_trigger_case) { create :pending_dacu_clearance_case }
  let(:approver)               { responded_trigger_case.approvers.first }
  let(:service)                { instance_double(CaseApprovalService,
                                                 call: true,
                                                 result: :ok) }

  describe 'approve' do
    before do
      sign_in approver
    end

    it 'authorizes' do
      expect {
        get :approve, params: { id: responded_trigger_case }
      } .to require_permission(:approve?)
              .with_args(approver, responded_trigger_case)
    end

    it 'renders the approve page' do
      get :approve, params: { id: responded_trigger_case }

      expect(response).to have_rendered('cases/approve')
    end
  end

  describe 'execute_approve' do
    before do
      sign_in approver
      allow(CaseApprovalService).to receive(:new).and_return(service)
    end

    it 'authorizes' do
      expect {
        patch :execute_approve, params: { id: responded_trigger_case }
      } .to require_permission(:approve?)
              .with_args(approver, responded_trigger_case)
    end

    it 'calls the case approval service' do
      patch :execute_approve, params: { id: responded_trigger_case }
      expect(CaseApprovalService).to have_received(:new)
                                       .with(hash_including(user: approver,
                                                            kase: responded_trigger_case))

      expect(service).to have_received(:call)
    end

    it 'flashes a notification' do
      patch :execute_approve, params: { id: responded_trigger_case }
      expect(flash[:notice])
        .to eq 'Disclosure has been notified that the response is pending clearance.'
    end

    it 'redirects to case detail page' do
      patch :execute_approve, params: { id: responded_trigger_case }
      expect(response).to redirect_to(case_path(responded_trigger_case))
    end
  end
end
