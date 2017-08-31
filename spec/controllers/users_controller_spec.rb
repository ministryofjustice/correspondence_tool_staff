require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:manager) { create :manager }
  let(:dacu)    { create :team_dacu }

  describe 'POST create' do
    let(:params) do
      {
        user: {
          full_name: 'TEst Er',
          email:     'test.er@localhost',
        },
        team_id: dacu.id
     }
    end

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

    it 'adds the user to the specified team' do
      post :create, params: params

      expect(User.last.teams).to eq [dacu]
    end

    it 'redirects to the users list if not team specified' do
      post :create, params: params
      expect(response).to redirect_to(team_path(dacu.id))
    end

    context 'with a team_id param' do
      let!(:dacu) { create :team_dacu }

      before do
        params[:team_id] = dacu.id
        params[:role]    = 'manager'
      end

      it 'adds the user to the given team with the given role' do
        post :create, params: params

        expect(dacu.managers).to include User.last
      end

      it 'redirects to the team details page' do
        post :create, params: params
        expect(response).to redirect_to(team_path(id: dacu.id))
      end
    end
  end

  describe 'PATCH update' do

    before { sign_in manager }

    let(:user) { create :user, full_name: 'John Smith', email: 'js@moj.com' }
    let(:team) { create :team }
    let(:params) do
      {
        'team_id' => team.id.to_s,
        'role' => 'responder',
        'user' => {
          'full_name' => 'Joanne Smythe',
          'email' => 'correspondence-staff-dev+joanne.smythe@digital.justice.gov.uk'
        },
        'commit' => 'Edit information officer',
        'id' => user.id.to_s
      }
    end

    it 'updates the user' do
      patch :update, params: params

      expect(user.reload.full_name).to eq 'Joanne Smythe'
      expect(user.email).to eq 'correspondence-staff-dev+joanne.smythe@digital.justice.gov.uk'
    end

    it 'redirects to team page' do
      patch :update, params: params
      expect(response).to redirect_to(team_path(team.id))
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
    let(:params) { { team_id: dacu.id,
                     role: 'manager' } }

    before { sign_in manager }

    it 'creates a new user' do
      get :new, params: params
      expect(assigns(:user)).to be_a User
      expect(assigns(:user).persisted?).to eq false
    end

    it 'assigns the team' do
      get :new, params: params
      expect(assigns(:team)).to eq dacu
    end

    it 'assigns the role' do
      get :new, params: params
      expect(assigns(:role)).to eq 'manager'
    end

    it 'returns an error if the team does not support the given role' do
      expect do
        get :new, params: params.merge(role: 'unsupported')
      end.to raise_error(RuntimeError)
    end
  end
end
