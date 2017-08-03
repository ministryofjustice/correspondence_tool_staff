require 'rails_helper'

RSpec.describe TeamsController, type: :controller do

  let(:bg)        { create :business_group }

  before(:each) do
    manager = create :manager
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
