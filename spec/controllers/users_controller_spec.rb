require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:manager) { create :manager }
  let(:dacu)    { create :team_dacu }

  describe 'POST create' do
    let(:params) { {
                     user: {
                       full_name: 'TEst Er',
                       email:     'test.er@localhost',
                     }
                   } }

    before { sign_in manager }

    it 'creates a user with the given params' do
      post :create, params: params

      expect(User.last).to have_attributes full_name: 'TEst Er',
                                           email: 'test.er@localhost'
    end

    it 'sets the user password to something random' do
      allow(SecureRandom).to receive(:random_number).with(any_args)
                               .and_return(7271817273818812)
      post :create, params: params
      user = User.last
      expect(user.valid_password?('1zln6qk2ncs')).to be true
    end

    it 'does not add the user to a team by default' do
      post :create, params: params

      expect(User.last.teams).to be_empty
    end

    context 'with a team_id param' do
      let!(:dacu) { create :team_dacu }
      it 'adds the user to the given team' do
        params[:team_id] = dacu.id
        post :create, params: params

        expect(dacu.users).to include User.last
      end
    end
  end

  describe 'GET index' do
    let(:responder!) { create :responder }

    before { sign_in manager }

    it 'retrieves all the users' do
      get :index
      expect(assigns(:users)).to match_array User.all
    end

    context 'with a team_id param' do
      let(:params) { { team_id: dacu.id } }

      it 'retrieves the teams users' do
        get :index, params: params
        expect(assigns(:users)).to match_array dacu.users
      end
    end
  end

  describe 'GET new' do
    before { sign_in manager }

    it 'creates a new user' do
      get :new
      expect(assigns(:user)).to be_a User
      expect(assigns(:user).persisted?).to eq false
    end

    context 'with a team_id param' do
      let(:params) { { team_id: dacu.id } }

      it 'retrieves team object' do
        get :new, params: params
        expect(assigns(:team)).to eq dacu
      end
    end
  end
end
