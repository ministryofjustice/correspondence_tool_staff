require 'rails_helper'

RSpec.shared_examples 'edit case spec' do
  context 'as a logged in non-manager' do
    let(:responder)             { find_or_create :foi_responder }

    before(:each)  do
      sign_in responder
      get :edit, params: { id: kase.id }
    end

    it 'redirects to case list' do
      expect(response).to redirect_to root_path
    end

    it 'displays error message in flash' do
      expect(flash[:alert]).to eq 'You are not authorised to edit this case.'
    end
  end

  context 'as a logged in manager' do
    let(:manager) { find_or_create :disclosure_bmt_user }

    before(:each) do
      sign_in manager
      get :edit, params: { id: kase.id }
    end

    it 'assigns case' do
      expect(assigns(:case)).to eq kase
    end

    it 'renders edit' do
      expect(response).to render_template :edit
    end
  end
end

