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

  describe 'GET business_areas_covered' do
    let(:params) { { id: business_unit.id } }

    before do
      sign_in manager
    end

    it 'authorises' do
      expect{
        get :business_areas_covered, params: params
      }.to require_permission(:create?)
               .with_args(manager, business_unit)
    end

    it 'assigns @team' do
      get :business_areas_covered, params: params
      expect(assigns(:team)).to eq business_unit
    end

    it 'assigns @creating_team' do
      get :business_areas_covered, params: params, flash:{"creating_team"=> true}
      expect(assigns(:creating_team)).to eq true
    end

    it 'renders the business_areas_covered template' do
      get :business_areas_covered, params: params
      expect(response).to render_template(:business_areas_covered)
    end
  end

  describe 'POST create_business_areas_covered' do
    let(:params) {
      {
          id: business_unit.id,
          team_property: {
              'value' => 'A new area covered'
          }
      }
    }

    before do
      sign_in manager
    end

    it 'authorises' do
      expect{
        post :create_business_areas_covered, params: params, xhr: true
      }.to require_permission(:create?)
               .with_args(manager, business_unit)
    end

    it 'assigns @team' do
      post :create_business_areas_covered, params: params, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it 'assigns @areas' do
      post :create_business_areas_covered, params: params, xhr: true
      expect(assigns(:areas)).to eq business_unit.areas
    end

    it 'creates a new area' do
      post :create_business_areas_covered, params: params, xhr: true
      expect(business_unit.reload.areas.count).to eq 2
    end

    it 'renders the create.js.erb' do
      post :create_business_areas_covered, params: params, xhr: true
      expect(response).to render_template('teams/business_areas/create')
    end
  end

  describe 'DELETE destroy_business_area' do
    let(:params) {
      {
          id: business_unit.id,
          area_id: business_unit.areas.first.id,
          team_property: {
              'value' => 'A new area covered'
          }
      }
    }

    before do
      sign_in manager
    end

    it 'authorises' do
      expect{
        delete :destroy_business_area, params: params, xhr: true
      }.to require_permission(:create?)
               .with_args(manager, business_unit)
    end

    it 'assigns @team' do
      delete :destroy_business_area, params: params, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it 'deletes the area' do
      old_area = business_unit.areas.first
      delete :destroy_business_area, params: params, xhr: true
      expect(business_unit.reload.areas).not_to include(old_area)
    end
    it 'renders the destroy.js.erb' do
      delete :destroy_business_area, params: params, xhr: true
      expect(response).to render_template('teams/business_areas/destroy')
    end
  end

  describe 'GET update_business_area_form' do
    let(:params) {
      {
          id: business_unit.id,
          area_id: business_unit.areas.first.id,
          'team_property' => {
              'value' => 'This was updated'
          }
      }
    }

    before do
      sign_in manager
    end

    it 'authorises' do
      expect{
        get :update_business_area_form, params: params, xhr: true
      }.to require_permission(:create?)
               .with_args(manager, business_unit)
    end

    it 'assigns @team' do
      get :update_business_area_form, params: params, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it 'renders the get_update_form.js.erb' do
      get :update_business_area_form, params: params, xhr: true
      expect(response).to render_template('teams/business_areas/get_update_form')
    end
  end


  describe 'PATCH update_business_area' do
    let(:params) {
      {
          id: business_unit.id,
          area_id: business_unit.areas.first.id,
          'team_property' => {
              'value' => 'This was updated'
          }
      }
    }

    before do
      sign_in manager
    end

    it 'authorises' do
      expect{
        patch :update_business_area, params: params, xhr: true
      }.to require_permission(:create?)
               .with_args(manager, business_unit)
    end

    it 'assigns @team' do
      patch :update_business_area, params: params, xhr: true
      expect(assigns(:team)).to eq business_unit
    end

    it 'updates the area' do
      old_area_value = business_unit.areas.first.value
      patch :update_business_area, params: params, xhr: true
      expect(business_unit.reload.areas.first.value).not_to eq old_area_value
      expect(business_unit.reload.areas.first.value).to eq "This was updated"
    end

    it 'renders the get_update_form.js.erb' do
      patch :update_business_area, params: params, xhr: true
      expect(response).to render_template('teams/business_areas/update')
    end
  end
end
