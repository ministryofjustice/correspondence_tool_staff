require "rails_helper"

describe Cases::LinksController, type: :controller do
  let(:kase) { create :case }
  let(:link_case) { create :case }
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:delete_params) {
    {
      case_id: kase.id, id: link_case.number
    }
  }

  let(:service) { double(CaseLinkingService, destroy: :ok) }

  describe '#destroy' do
    before do
      allow(CaseLinkingService).to receive(:new).and_return(service)
      sign_in manager
    end

    it 'authorizes' do
      expect { delete :destroy, params: delete_params }
        .to require_permission(:new_case_link?).with_args(manager, kase)
    end

    it 'calls the CaseLinkingService destroy method' do
      delete :destroy, params: delete_params

      expect(CaseLinkingService)
        .to have_received(:new).with(
          manager,
          kase,
          delete_params[:id]
        )
      expect(service).to have_received(:destroy)
    end

    it 'notifies the user of the success' do
      delete :destroy, params: delete_params
      expect(flash[:notice])
        .to eq "The link to case #{link_case.number} has been removed."
    end

    context 'failed request' do
      let(:service) { double(CaseLinkingService, destroy: :failed) }

      it 'notifies the user of the failure' do
        delete :destroy, params: delete_params
        expect(flash[:alert])
          .to eq "Unable to remove the link to case #{link_case.number}"
        expect(:result).to redirect_to(case_path(kase.id))
      end
    end

  end
end
