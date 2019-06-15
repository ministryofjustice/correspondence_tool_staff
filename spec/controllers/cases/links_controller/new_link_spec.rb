require "rails_helper"

describe Cases::LinksController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:kase)    { create :case }

  before do
    sign_in manager
  end

  describe '#new' do
    it 'authorizes' do
      expect { get :new, params: { case_id: kase.id }}
        .to require_permission(:new_case_link?).with_args(manager, kase)
    end

    it 'sets @case' do
      get :new, params: { case_id: kase.id }
      expect(assigns(:case)).to eq kase
    end

    it 'renders the template' do
      get :new, params: { case_id: kase.id }
      expect(response).to render_template(:new)
    end
  end
end
