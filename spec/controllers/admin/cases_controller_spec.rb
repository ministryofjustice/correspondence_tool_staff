require "rails_helper"

describe Admin::CasesController do
  describe "#index" do
    let(:admin)   { create :admin }
    let(:manager) { create :manager }
    let(:dacu)    { find_or_create :team_dacu }

    context "when authenticated admin" do
      before { sign_in admin }

      it "retrieves all cases" do
        get :index

        expect(assigns(:cases)).to match_array Case::Base.all
      end

      it "renders the index view" do
        get :index

        expect(response).to have_rendered("admin/cases/index")
      end
    end
  end
end
