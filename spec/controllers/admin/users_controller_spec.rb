require "rails_helper"

describe Admin::UsersController do
  describe "GET index" do
    let(:admin)   { create :admin }

    context "when authenticated admin" do
      before do
        User.first.soft_delete
        sign_in admin
      end

      it "retrieves all the users including soft deleted" do
        get :index

        expect(assigns(:users)).to match_array User.unscoped
      end

      it "renders the index view" do
        get :index

        expect(response).to have_rendered("admin/users/index")
      end

      context "when searching" do
        it "retrieves users matching the search term" do
          get :index, params: { search_for: "Branston" }

          expect(assigns(:users)).to match_array User.where(full_name: "branston registry responding user")
        end
      end
    end
  end
end
