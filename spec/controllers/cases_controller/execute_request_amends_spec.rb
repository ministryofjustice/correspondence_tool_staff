require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:pending_private_clearance_case) { create :pending_private_clearance_case }
  let(:private_officer)                { find_or_create :private_officer }
  let(:service)                        { instance_double(CaseRequestAmendsService,
                                                         call: true) }
    let(:something)                        { instance_double(SetDraftTimelinessService,
                                                           call: true) }


  describe 'PATCH execute_request_amends' do
    context 'Full approval FOI' do
      before do
        sign_in private_officer
        allow(CaseRequestAmendsService).to receive(:new).and_return(service)
      end

      it 'authorizes' do
        expect {
          patch :execute_request_amends,
                params: { id: pending_private_clearance_case, case: {request_amends_comment: "Oh my!"} }
        } .to require_permission(:execute_request_amends?)
                .with_args(private_officer, pending_private_clearance_case)
      end

      it 'calls the case request amends service' do
        patch :execute_request_amends,
              params: { id: pending_private_clearance_case, case: {request_amends_comment: "Oh my!"} }
        expect(CaseRequestAmendsService)
          .to have_received(:new).with(user: private_officer,
                                       kase: pending_private_clearance_case,
                                       message: "Oh my!")
        expect(service).to have_received(:call)
      end

      it 'flashes a notification' do
        patch :execute_request_amends,
              params: { id: pending_private_clearance_case, case: {request_amends_comment: "Oh my!"} }
        expect(flash[:notice])
          .to eq 'You have requested amends to this case\'s response.'
      end

      it 'redirects to case detail page' do
        patch :execute_request_amends,
              params: { id: pending_private_clearance_case, case: {request_amends_comment: "Oh my!"} }
        expect(response).to redirect_to(case_path(pending_private_clearance_case))
      end
    end

    context 'trigger SAR' do
      let(:trigger_sar)             { create :pending_dacu_clearance_sar,
                                             approver: disclosure_specialist }
      let(:disclosure_specialist)   { find_or_create :disclosure_specialist }

      before do
        sign_in disclosure_specialist
        allow(CaseRequestAmendsService).to receive(:new).and_return(service)
        allow(SetDraftTimelinessService).to receive(:new).and_return(something)

      end

      it 'calls the case request amends service with disclosure specialist' do
        patch :execute_request_amends,
              params: { id: trigger_sar, case: {request_amends_comment: "Sneaky puppies"} }
        expect(CaseRequestAmendsService)
          .to have_received(:new).with(user: disclosure_specialist,
                                       kase: trigger_sar,
                                       message: "Sneaky puppies")
        expect(service).to have_received(:call)
      end

      it 'flashes a notification for SARs' do
        patch :execute_request_amends,
              params: { id: trigger_sar, case: {request_amends_comment: "Sneaky puppies"} }
        expect(flash[:notice])
          .to eq 'Information Officer has been notified a redraft is needed.'
      end

      it 'sets the draft Timeliness' do
        patch :execute_request_amends,
              params: { id: trigger_sar, case: {request_amends_comment: "Sneaky puppies", draft_compliant: 'yes'} }
        expect(SetDraftTimelinessService)
          .to have_received(:new).with(kase: trigger_sar)
        expect(something).to have_received(:call)
      end
    end
  end
end
