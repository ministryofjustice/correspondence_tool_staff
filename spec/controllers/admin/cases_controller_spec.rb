require "rails_helper"

describe Admin::CasesController do
  let(:manager) { create :manager }

  describe '#index' do
    it 'renders the index view' do
      sign_in manager
      get :index
      expect(response).to have_rendered('admin/cases/index')
    end
  end
end
