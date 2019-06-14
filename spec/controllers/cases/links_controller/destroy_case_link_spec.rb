require "rails_helper"

describe CasesController, type: :controller do
  describe 'DELETE destroy_case_link' do
    let(:kase)      { create :case }
    let(:link_case) { create :case }
    let(:manager)  { find_or_create :disclosure_bmt_user }
    let(:delete_params)       { { id: kase.id,
                                 linked_case_number: link_case.number
                                 }
    }

    let(:service) { double(CaseLinkingService, destroy: :ok) }

    before do
      allow(CaseLinkingService).to receive(:new).and_return(service)
      sign_in manager
    end

    it 'authorizes' do
      expect {
        delete :destroy_case_link, params: delete_params
      } .to require_permission(:new_case_link?)
              .with_args(manager, kase)
    end

    it 'calls the CaseLinkingService destroy method' do
      delete :destroy_case_link, params: delete_params
      expect(CaseLinkingService)
        .to have_received(:new).with(manager,
                                     kase,
                                     delete_params[:linked_case_number])

      expect(service).to have_received(:destroy)
    end

    it 'notifies the user of the success' do
      delete :destroy_case_link, params: delete_params
      expect(flash[:notice])
        .to eq "The link to case #{ link_case.number } has been removed."
    end

    context 'failed request' do
      let(:service) { double(CaseLinkingService, destroy: :failed) }

      it 'notifies the user of the failure' do
        delete :destroy_case_link, params: delete_params
        expect(flash[:alert])
          .to eq "Unable to remove the link to case #{ link_case.number }"
        expect(:result).to redirect_to(case_path(kase.id))
      end
    end

  end
end
