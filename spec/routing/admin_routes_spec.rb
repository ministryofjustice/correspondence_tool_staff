require "rails_helper"

describe "admin routes", type: :routing do
  let(:admin)         { create :admin }
  let(:manager)       { create :manager }

  describe "/admin", type: :request do
    context "when an admin" do
      it "redirects admins to /admin/cases" do
        login_as admin
        get "/admin"
        expect(response).to redirect_to "/admin/cases"
      end
    end

    context "when a non-admin" do
      it "raises an error" do
        login_as manager
        get "/admin"
        expect(response).to be_not_found
      end
    end
  end

  describe "/admin/cases", type: :request do
    context "when an admin" do
      it "loads cases" do
        login_as admin
        get "/admin/cases"
        expect(response).to be_successful
      end
    end

    context "when a non-admin" do
      it "raises an error" do
        login_as manager
        get "/admin/cases"
        expect(response).to be_not_found
      end
    end
  end
end
