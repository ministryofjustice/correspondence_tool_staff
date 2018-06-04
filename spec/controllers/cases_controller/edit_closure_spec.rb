require "rails_helper"

describe CasesController do
  describe 'GET edit_closure' do
    let(:kase)    { create :closed_sar }
    let(:manager) { create :disclosure_bmt_user }

    before do
      sign_in manager
    end

    it 'authorises with update_closure? policy' do
      expect{
        get :edit_closure, params: { id: kase.id }
      }.to require_permission(:update_closure?)
             .with_args(manager, kase)
    end

    it 'renders the close page' do
      get :edit_closure, params: { id: kase.id }
      expect(response).to render_template :edit_closure
    end
  end
end
