require 'rails_helper'

RSpec.describe PagesController, type: :controller do

  describe "GET #accessibility" do
    let(:user) { create(:user) }
    
    before {
      sign_in user
    }

    it "returns http success" do
      get :accessibility
      expect(response).to have_http_status(:success)
    end
  end

end

