require 'rails_helper'
require 'devise'

RSpec.describe PasswordsController, type: :controller do
  describe 'POST create' do
    let!(:user)  { create :user }
    let!(:deactivated_user) { create :deactivated_user }
    let(:params){
      {
        user:{
          email: deactivated_user.email
        }
      }
    }

    context 'user is deactivated' do
      it 'sends an email and shows message' do
        @request.env["devise.mapping"] = Devise.mappings[:user]

        mailer = double("mailer")
        expect(DeviseMailer).to receive(:account_not_active).and_return(mailer)
        expect(mailer).to receive(:deliver_later)
        post :create, params: params

        expect(flash[:notice]).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
      end
    end

    context 'user is not registered' do
      it 'does not send any email and shows message' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        params[:email] = Faker::Internet.email

        post :create, params: params

        expect(DeviseMailer).not_to receive(:account_not_active)
        expect(DeviseMailer).not_to receive(:reset_password_instructions)

        expect(flash[:notice]).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
      end
    end
  end
end
