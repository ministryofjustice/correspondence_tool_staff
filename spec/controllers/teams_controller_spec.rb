require 'rails_helper'

RSpec.describe TeamsController, type: :controller do

  let(:bg)              { create :business_group }
  let(:directorate)     { create :directorate, business_group: bg }
  let(:business_unit)   { create :business_unit, directorate: directorate, name: 'AAA' }
  let(:business_unit2)  { create :business_unit, directorate: directorate, name: 'BBB' }
  let(:manager)         { create :manager }

  describe 'GET index' do
    context 'logged in as a manager' do

      before(:each) { sign_in manager }

      it 'loads all business groups' do
        expect(Team).to receive(:where).with(type: 'BusinessGroup').and_return([bg])
        get :index
        expect(assigns(:teams)).to eq [bg]
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    context 'logged in as a non-manager' do
      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end
      it 'loads all teams the the responder is a member of' do
        get :index
        expect(assigns(:teams)).to eq [ business_unit, business_unit2 ]
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:teams_for_user)
      end
    end
  end

  describe 'GET show' do
    context 'logged in as a manager' do

      before(:each) do
        sign_in manager
        @bg = create :business_group
        @dir_1 = create :directorate, business_group: @bg
        @dir_2 = create :directorate, business_group: @bg
      end

      it 'loads the team and children' do
        get :show, params: { id: @bg.id }
        expect(assigns(:team)).to eq @bg
        expect(assigns(:children)).to match_array [@dir_1, @dir_2]
      end

      it 'renders the show template' do
        get :show, params: { id: @bg.id }
        expect(response).to render_template(:show)
      end
    end

    context 'logged in as a non-manager' do

      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end

      context 'viewing a team that he is a member of' do
        it 'loads the team' do
          get :show, params: {id: business_unit.id }
        end
      end

      context 'viewing a team that he isnt a member of' do
        it 'loads the team and children' do
          get :show, params: { id: business_unit.id }
          expect(assigns(:team)).to eq business_unit
          expect(assigns(:children)).to be_empty
        end

        it 'renders the show template' do
          get :show, params: { id: business_unit.id }
          expect(response).to render_template(:show)
        end
      end
    end
  end

  describe 'POST create' do

    context 'signed in as a manager' do

      before(:each) { sign_in manager }

      describe 'POST create' do
        let(:params) {
          {
            'team' => {
              'name' => 'Frog sizing unit',
              'email' => 'frogs@a.com',
              'team_lead' => 'Stephen Richards',
              'parent_id' => directorate.id,
              'role' => 'responder'
            },
            'team_type' => 'bu',
            'commit' => 'Submit'}
        }

        it 'creates a user with the given params' do
          post :create, params: params

          bu = BusinessUnit.last
          expect(bu.name).to eq 'Frog sizing unit'
          expect(bu.email).to eq 'frogs@a.com'
          expect(bu.team_lead).to eq 'Stephen Richards'
          expect(bu.parent).to eq directorate
        end
      end
    end

    context 'signed in as a non-manager' do

      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end

      it 'redirects to root with unauth message in flash' do
        post :create, params:  { 'team' => {  'name' => 'Frog sizing unit' } }
        expect(flash['alert']).to eq 'You are not authorised to add new teams'
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET edit' do

    context 'signed in as a manager' do
      let(:params) { { id: bg.id } }

      before do
        sign_in manager
      end

      it 'authorises' do
        expect{
          get :edit, params: params
        }.to require_permission(:edit?)
               .with_args(manager, bg)
      end

      it 'assigns @team' do
        get :edit, params: params
        expect(assigns(:team)).to eq bg
      end
    end

    context 'signed in as a non manager' do

      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end

      context 'team that the responder ia a member of' do
        let(:params) { { id: business_unit.id } }

        it 'authorises' do
          expect{
            get :edit, params: params
          }.to require_permission(:edit?)
                 .with_args(@responder, business_unit)
        end

        it 'assigns @team' do
          get :edit, params: params
          expect(assigns(:team)).to eq business_unit
        end

        it 'renders edit page' do
          get :edit, params: params
          expect(response).to render_template(:edit)
        end
      end

      context 'team that the repsonder is not a member of' do
        let(:other_bu) { create :business_unit, directorate: directorate }
        let(:params) { { id: other_bu.id } }

        it 'redirects to root path with unauth message' do
          get :edit, params: params
          expect(flash['alert']).to eq 'You are not authorised to edit this team'
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'PATCH update' do

    context 'logged in as a manager' do
      let(:params) { { id: business_unit.id,
                          team: {
                            name: 'New Name',
                            email: 'n00b@localhost',
                            team_lead: 'New Team Lead',
                          } } }

      before do
        sign_in manager
      end

      it 'authorises' do
        expect{
          patch :update, params: params
        }.to require_permission(:update?)
               .with_args(manager, business_unit)
      end

      it 'updates the given team' do
        patch :update, params: params

        business_unit.reload
        expect(business_unit.name).to  eq 'New Name'
        expect(business_unit.email).to eq 'n00b@localhost'
        expect(business_unit.team_lead).to eq 'New Team Lead'
      end
    end

    context 'logged in as a non-manager' do

      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end

      context 'team that the responder ia a member of' do
        let(:other_bu) { create :business_unit, directorate: directorate, name: 'CCCC', team_lead: 'Johnny Olds' }
        let(:params) do
          {
            'id' => other_bu.id,
            'team' => {
              'name' => 'New Frog sizing unit',
              'email' => 'frogs@a.com',
              'team_lead' => 'Johnny New',
              'parent_id' => directorate.id,
              'role' => 'responder'
            },
            'team_type' => 'bu',
            'commit' => 'Submit'}
        end

        it 'returns success' do
          patch :update, params: params
          expect(response).to redirect_to(root_path)
        end

        it 'updates the teaam details' do
          patch :update, params: params
          t = other_bu.reload
          expect(t.name).to eq 'CCCC'
          expect(t.team_lead).to eq 'Johnny Olds'
        end
      end

      context 'team that the repsonder is not a member of' do
        let(:params) do
          {
            'id' => business_unit.id,
            'team' => {
              'name' => 'New Frog sizing unit',
              'email' => 'frogs@a.com',
              'team_lead' => 'Johnny New',
              'parent_id' => directorate.id,
              'role' => 'responder'
            },
            'team_type' => 'bu',
            'commit' => 'Submit'}
        end

        it 'renders the root path with unauth message' do

        end
        it 'does not update the team'
      end
    end
  end

  describe 'GET new' do
    context 'logged in as a non manager' do

      before(:each) do
        @responder = create :responder, responding_teams: [ business_unit, business_unit2 ]
        sign_in @responder
      end

      it 'redirects to root with unauth message in flash' do
        get :new, params: { team_type: 'bu'}
        expect(flash['alert']).to eq 'You are not authorised to add new teams'
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
