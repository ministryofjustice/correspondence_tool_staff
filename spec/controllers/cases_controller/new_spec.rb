require "rails_helper"

describe CasesController, typ: :controller do
  describe '#new' do
    let(:manager) { create :disclosure_bmt_user }
    let(:params) { { case: { type: 'Case::FOI::Standard' } } }

    before do
      sign_in manager
    end

    it 'authorizes' do
      expect { get :new, params: params }
        .to require_permission(:can_add_case?).with_args(manager, Case::FOI::Standard)
    end

    it 'renders the new template' do
      get :new, params: params
      expect(response).to render_template(:new)
    end
  end
end
