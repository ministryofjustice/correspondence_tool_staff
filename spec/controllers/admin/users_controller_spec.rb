require "rails_helper"

describe Admin::UsersController do
  describe "GET index" do
    let(:admin)   { create :admin }
    let(:manager) { create :manager }
    let(:dacu)    { find_or_create :team_dacu }

    context "authenticated admin" do
      before { sign_in admin }

      it "retrieves all the users" do
        get :index

        expect(assigns(:users)).to match_array User.all
      end

      it "renders the index view" do
        get :index

        expect(response).to have_rendered("admin/users/index")
      end
    end
  end
end
