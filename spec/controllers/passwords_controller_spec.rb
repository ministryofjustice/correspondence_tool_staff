require 'rails_helper'
require 'devise'

RSpec.describe PasswordsController, type: :controller do
  describe 'POST create' do
    let(:mailer) { double ActionNotificationsMailer, account_not_active}
    let!(:user)  { create :user }
    let!(:deactivated_user) { create :deactivated_user }
    let(:params){
      {
        user:{
          email: user.email
        }
      }
    }

    before do
      allow(ActionNotificationsMailer).to receive_message_chain(:account_not_active,
                                                     :deliver_later)
    end

    context 'user is registered' do
      it 'redirect and shows message' do
        @request.env["devise.mapping"] = Devise.mappings[:user]

        post :create, params: params

        expect(ActionNotificationsMailer).to have_received(:account_not_active)
                                      .with user.email
        expect(mailer).to receive(:deliver_later).exactly(1)

        expect(flash[:notice]).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
      end
    end

    context 'user is deactivated' do
      it 'redirect and shows message' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        params[:email] = deactivated_user.email

        post :create, params: params
        expect(ActionNotificationsMailer).to have_received(:account_not_active)
                                      .with deactivated_user.email
        expect(mailer).to receive(:deliver_later).exactly(1)

        expect(flash[:notice]).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
      end
    end

    context 'user is not registered' do
      it 'redirect and shows message' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        params[:email] = Faker::Internet.email

        post :create, params: params
        expect(ActionNotificationsMailer).to have_received(:account_not_active)
                                      .with params[:email]
        expect(mailer).to receive(:deliver_later).exactly(1)

        expect(flash[:notice]).to eq "If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes."
      end
    end
  end
end
