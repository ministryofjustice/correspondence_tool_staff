require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:pending_private_clearance_case) { create :pending_private_clearance_case }
  let(:private_officer)                { create :private_officer }
  let(:service)                        { instance_double(CaseRequestAmendsService,
                                                         call: true) }

  describe 'PATCH execute_request_amends' do
    before do
      sign_in private_officer
      allow(CaseRequestAmendsService).to receive(:new).and_return(service)
    end

    it 'authorizes' do
      expect {
        patch :execute_request_amends,
              params: { id: pending_private_clearance_case }
      } .to require_permission(:execute_request_amends?)
              .with_args(private_officer, pending_private_clearance_case)
    end

    it 'calls the case request amends service' do
      patch :execute_request_amends,
            params: { id: pending_private_clearance_case }
      expect(CaseRequestAmendsService)
        .to have_received(:new).with(user: private_officer,
                                     kase: pending_private_clearance_case)
      expect(service).to have_received(:call)
    end

    it 'flashes a notification' do
      patch :execute_request_amends,
            params: { id: pending_private_clearance_case }
      expect(flash[:notice])
        .to eq "You have requested amends to case " +
               "#{pending_private_clearance_case.number}" +
               " - #{pending_private_clearance_case.subject}."
    end

    it 'redirects to cases page' do
      patch :execute_request_amends,
            params: { id: pending_private_clearance_case }
      expect(response).to redirect_to(cases_path)
    end
  end
end
