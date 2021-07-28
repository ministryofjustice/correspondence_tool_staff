require 'rails_helper'

RSpec.describe PagesController, type: :controller do

  describe "GET #accessibility" do
    it "returns http success" do
      get :accessibility
      expect(response).to have_http_status(:success)
    end
  end

end