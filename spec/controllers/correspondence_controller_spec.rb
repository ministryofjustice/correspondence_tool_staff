require 'rails_helper'

RSpec.describe CorrespondenceController, type: :controller do

  let(:all_correspondence) { create_list(:correspondence, 5) }

  context 'GET index' do

    before { get :index }

    it 'assigns @correspondence' do
      expect(assigns(:correspondence)).to match(all_correspondence)
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end
  end

  context 'GET edit' do

    before do
      id = all_correspondence.first.id
      get :edit, params: { id: id }
    end

    it 'assigns @correspondence' do
      expect(assigns(:correspondence)).to eq(Correspondence.first)
    end

    it 'renders the edit template' do
      expect(response).to render_template(:edit)
    end
  end

  context 'PATCH update' do

    before do
      id = all_correspondence.first.id
      patch :update, params: { id: id, correspondence: { category: 'freedom_of_information_reuqest', topic: 'courts' } }
    end

    it 'updates the correspondence record' do
      expect(Correspondence.first.topic).to eq 'courts'
    end
  end

  context 'PATCH assign' do

    before do
      id = all_correspondence.first.id
      user_id = create(:user)
      patch :assign, params: { id: id, correspondence: { user_id: user_id } }
    end

    it 'assigns correspondence to a user' do
      expect(Correspondence.first.drafter).to eq User.first
    end

  end

end
