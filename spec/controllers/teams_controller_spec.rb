require 'rails_helper'

RSpec.describe TeamsController, type: :controller do

  let(:bg)            { create :business_group }
  let(:directorate)   { create :directorate, business_group: bg }
  let(:business_unit) { create :business_unit, directorate: directorate }
  let(:manager)       { create :manager }

  context 'logged in as a non-manager'do
    before(:each) do
      responder = create :responder
      sign_in responder
    end

    describe 'POST create' do
      let(:params) {
        {
          'team' => {
            'name' => 'Frog sizing unit',
            'email' => 'frogs@a.com',
            'team_lead' => 'Stephen Richards',
            'parent_id' => directorate.id
          },
          'commit' => 'Submit'}
      }

      before { sign_in manager }

      it 'creates a user with the given params' do
        post :create, params: params

        bu = BusinessUnit.last
        expect(bu.name).to eq 'Frog sizing unit'
        expect(bu.email).to eq 'frogs@a.com'
        expect(bu.team_lead).to eq 'Stephen Richards'
        expect(bu.parent).to eq directorate
      end
    end

    describe 'GET index' do
      it 'redirects to new root path' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'GET show' do
      it 'redirects to new root path' do
        bg = create :business_group
        get :show, params: { id: bg.id }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'logged in as a manager' do

    before(:each) do
      sign_in manager
    end


    describe 'GET index' do
      it 'loads all business groups' do
        expect(BusinessGroup).to receive(:all).and_return([bg])
        get :index
        expect(assigns(:teams)).to eq [bg]
      end

      it 'renders the index template' do
        get :index
        expect(response).to render_template(:index)
      end
    end

    describe 'GET show' do
      before(:each) do
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
  end

  describe 'GET edit' do
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

  describe 'PATCH update' do
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
end
