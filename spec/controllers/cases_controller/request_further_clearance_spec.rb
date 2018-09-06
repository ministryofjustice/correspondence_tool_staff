require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:manager)           { create :disclosure_bmt_user }
  let(:accepted_case)     { create :accepted_case  }
  let(:service)           { instance_double(RequestFurtherClearanceService,
                                            call: :ok) }

  describe 'PATCH request_further_clearance' do
    context "FOI" do
      before do
        sign_in manager
        allow(RequestFurtherClearanceService).to receive(:new).and_return(service)
      end

      it 'authorizes' do
        expect {
          patch :request_further_clearance, params: { id: accepted_case.id }
        } .to require_permission(:request_further_clearance?)
                .with_args(manager, accepted_case)
      end

      it 'sets @case' do
        patch :request_further_clearance, params: { id: accepted_case.id }
        expect(assigns(:case)).to eq accepted_case
      end

      it 'calls the Request further clearance service' do
        patch :request_further_clearance, params: { id: accepted_case.id }
        expect(RequestFurtherClearanceService).to have_received(:new)
                                         .with(hash_including(user: manager,
                                                              kase: accepted_case))

        expect(service).to have_received(:call)
      end

      it 'flashes a notification' do
        patch :request_further_clearance, params: { id: accepted_case.id }
        expect(flash[:notice])
          .to eq 'Further clearance requested'
      end

      it 'redirects to case details page' do
        patch :request_further_clearance, params: { id: accepted_case.id }
        expect(response).to redirect_to(case_path(accepted_case))
      end
    end

    context "SAR" do
      let(:accepted_sar) {create :accepted_sar}
      before do
        sign_in manager
        allow(RequestFurtherClearanceService).to receive(:new).and_return(service)
      end

      it 'authorizes' do
        expect {
          patch :request_further_clearance, params: { id: accepted_sar.id }
        } .to require_permission(:request_further_clearance?)
                .with_args(manager, accepted_sar)
      end

      it 'sets @case' do
        patch :request_further_clearance, params: { id: accepted_sar.id }
        expect(assigns(:case)).to eq accepted_sar
      end

      it 'calls the Request further clearance service' do
        patch :request_further_clearance, params: { id: accepted_sar.id }
        expect(RequestFurtherClearanceService).to have_received(:new)
                                         .with(hash_including(user: manager,
                                                              kase: accepted_sar))

        expect(service).to have_received(:call)
      end

      it 'flashes a notification' do
        patch :request_further_clearance, params: { id: accepted_sar.id }
        expect(flash[:notice])
          .to eq 'Further clearance requested'
      end

      it 'redirects to case details page' do
        patch :request_further_clearance, params: { id: accepted_sar.id }
        expect(response).to redirect_to(case_path(accepted_sar))
      end
    end
  end
end
