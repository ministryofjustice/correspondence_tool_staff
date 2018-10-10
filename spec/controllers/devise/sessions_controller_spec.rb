require 'rails_helper'

describe Devise::SessionsController do

  describe 'signing in' do

    let(:email)                 { 'abc@moj.com' }
    let(:password)              { '102PettyFrance'  }
    let(:bad_pass)              { 'xxx' }
    let(:user)                  { create :user, email: email, password: password }
    let(:bad_user)              { create :user, email: email, password: password, failed_attempts: 3 }
    let(:notification_double)   { double 'DeviseMailerUnlockInstructionsNotification' }

    context 'correct password' do
      it 'signs the user in' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        post :create, params: { user: {email: user.email, password: user.password } }
        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq 'Signed in successfully.'
      end
    end

    context 'bad password' do
      it 'does not sign in' do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        post :create, params: { user: {email: user.email, password: bad_pass } }
        expect(response).to be_success
        expect(flash[:alert]).to eq 'Invalid email or password.'
      end

      context 'four or more failed attempts' do
        it 'sends unlock notification' do
          expect(DeviseMailer).to receive(:unlock_instructions).and_return(notification_double)
          expect(notification_double).to receive(:deliver)
          @request.env["devise.mapping"] = Devise.mappings[:user]
          post :create, params: { user: {email: bad_user.email, password: bad_pass } }
        end

        it 'locks the user' do
          allow(DeviseMailer).to receive(:unlock_instructions).and_return(notification_double)
          allow(notification_double).to receive(:deliver)
          @request.env["devise.mapping"] = Devise.mappings[:user]
          post :create, params: { user: {email: bad_user.email, password: bad_pass } }
          bad_user.reload
          expect(bad_user.failed_attempts).to eq 4
          expect(bad_user.unlock_token).to be_present
          expect(bad_user.access_locked?).to be true
        end
      end
    end

  end


end
