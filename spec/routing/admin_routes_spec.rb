require "rails_helper"

describe "admin routes", type: :routing do
  let(:admin)         { create :admin }
  let(:manager)       { create :manager }

  describe "/admin", type: :request do
    context "as an admin" do
      it "redirects admins to /admin/cases" do
        login_as admin
        get "/admin"
        expect(response).to redirect_to "/admin/cases"
      end
    end

    context "as a non-admin" do
      it "raises an error" do
        login_as manager
        expect {
          get "/admin"
        }.to raise_error ActionController::RoutingError
      end
    end
  end

  describe "/admin/cases", type: :request do
    context "as an admin" do
      it "loads cases" do
        login_as admin
        get "/admin/cases"
        expect(response).to be_successful
      end
    end

    context "as a non-admin" do
      it "raises an error" do
        login_as manager
        expect {
          get "/admin/cases"
        }.to raise_error ActionController::RoutingError
      end
    end
  end
end
