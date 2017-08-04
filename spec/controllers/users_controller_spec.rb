require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:manager) { create :manager }

  describe 'GET index' do
    before { sign_in manager }
    it 'retrieves all the users' do
      responder = create :responder
      get :index
      expect(assigns(:users)).to match_array User.all
    end
  end
end
