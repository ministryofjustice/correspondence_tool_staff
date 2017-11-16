require "rails_helper"

describe CasesController, type: :controller do
  describe 'POST execute_new_case_link' do
    let(:kase)      { create :case }
    let(:link_case) { create :case }
    let(:manager)  { find_or_create :disclosure_bmt_user }
    let(:post_params)       { { id: kase.id,
                                 case: {
                                   linked_case_number: link_case.number
                                 }
    }}

    let(:service) { double(CaseLinkingService, call: :ok) }

    before do
      allow(CaseLinkingService).to receive(:new).and_return(service)
      sign_in manager
    end

    it 'authorizes' do
      expect {
        post :execute_new_case_link, params: post_params
      } .to require_permission(:new_case_link?)
              .with_args(manager, kase)
    end

    it 'calls the CaseLinkingService' do
      post :execute_new_case_link, params: post_params
      expect(CaseLinkingService)
        .to have_received(:new).with(manager,
                                     kase,
                                     post_params[:case][:linked_case_number])

      expect(service).to have_received(:call)
    end

    it 'notifies the user of the success' do
      post :execute_new_case_link, params: post_params
      expect(flash[:notice])
        .to eq "Case #{ link_case.number } has been linked to this case"
    end

    context 'validation error' do
      let(:service) { double(CaseLinkingService, call: :validation_error) }

      it 'renders the new_link page' do
        post :execute_new_case_link, params: post_params
        expect(:result).to have_rendered(:new_case_link)
      end
    end

    context 'failed request' do
      let(:service) { double(CaseLinkingService, call: :error) }

      it 'notifies the user of the failure' do
        post :execute_new_case_link, params: post_params
        expect(flash[:alert])
          .to eq "Unable to create a link to case #{ link_case.number }"
        expect(:result).to redirect_to(case_path(kase.id))
      end
    end
  end
end
