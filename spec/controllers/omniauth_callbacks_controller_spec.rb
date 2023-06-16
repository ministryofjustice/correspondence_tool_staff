require "rails_helper"
require "devise"

RSpec.describe OmniauthCallbacksController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET azure_activedirectory_v2" do
    let(:user_email)  { "test_user@foobar.com" }
    let(:error_flash) { "Account not found or deactivated." }

    before do
      @request.env["omniauth.auth"] = { "info" => { "email" => user_email } }
    end

    context "user is not registered" do
      it "redirects to the sign in page and shows error message" do
        get :azure_activedirectory_v2

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq(error_flash)
      end
    end

    context "user is deactivated" do
      let!(:user) { create :deactivated_user, email: user_email }

      it "redirects to the sign in page and shows error message" do
        get :azure_activedirectory_v2

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq(error_flash)
      end
    end

    context "user exists and is active" do
      let!(:user) { create :user, email: user_email }

      it "redirects to the home page" do
        get :azure_activedirectory_v2

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_nil
      end
    end

    context "user is found irrespective of their email letter case" do
      let!(:user) { create :user, email: user_email.downcase } # user email in our database
      let(:user_email) { super().upcase } # user email as returned by Active Directory

      it "redirects to the home page" do
        get :azure_activedirectory_v2

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_nil
      end
    end
  end
end
