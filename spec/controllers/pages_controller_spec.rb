require 'rails_helper'

RSpec.describe PagesController, type: :controller do

  describe "GET #accessibility logged in" do
    let(:user) { create(:user) }
    
    before {
      sign_in user
    }

    it "returns http success" do
      get :accessibility
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #accessibility logged out" do
    it "returns http success" do
      get :accessibility
      expect(response).to have_http_status(:success)
    end
  end

end

