require "rails_helper"
require "devise"

RSpec.describe PasswordsController, type: :controller do
  describe "POST create" do
    let!(:user)             { create :user, email: "existing_user@moj.com" }
    let!(:deactivated_user) { create :deactivated_user }
    let(:success_message)   { "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes." }
    let(:params) do
      {
        user: {
          email: deactivated_user.email,
        },
      }
    end

    before { @request.env["devise.mapping"] = Devise.mappings[:user] }

    context "user is deactivated" do
      it "sends reset password mail" do
        mailer = double("mailer")
        expect(DeviseMailer).to receive(:reset_password_instructions).and_return(mailer)
        expect(mailer).to receive(:deliver)
        post(:create, params:)

        expect(flash[:notice]).to eq success_message
      end
    end

    context "user is not registered" do
      it "does not send any email and shows message" do
        params[:user][:email] = Faker::Internet.email

        post(:create, params:)

        expect(DeviseMailer).not_to receive(:account_not_active)
        expect(DeviseMailer).not_to receive(:reset_password_instructions)

        expect(flash[:notice]).to eq success_message
      end
    end

    context "succeessful password reset" do
      context "email specified in lower case" do
        it "sends an email" do
          params[:user][:email] = user.email

          mailer = double("mailer", deliver: nil)
          expect(DeviseMailer).not_to receive(:account_not_active)
          expect(DeviseMailer).to receive(:reset_password_instructions).and_return(mailer)
          expect(mailer).to receive(:deliver)
          post(:create, params:)

          expect(flash[:notice]).to eq success_message
        end
      end

      context "email specified in upper case" do
        it "sends an email" do
          params[:user][:email] = user.email.upcase

          mailer = double("mailer", deliver: nil)
          expect(DeviseMailer).not_to receive(:account_not_active)
          expect(DeviseMailer).to receive(:reset_password_instructions).and_return(mailer)
          expect(mailer).to receive(:deliver)
          post(:create, params:)

          expect(flash[:notice]).to eq success_message
        end
      end
    end
  end
end
