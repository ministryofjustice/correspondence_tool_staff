require "rails_helper"

describe Admin::CasesController do
  let(:admin) { create :admin }

  describe '#index' do
    it 'renders the index view' do
      sign_in admin
      get :index
      expect(response).to have_rendered('admin/cases/index')
    end
  end
end
