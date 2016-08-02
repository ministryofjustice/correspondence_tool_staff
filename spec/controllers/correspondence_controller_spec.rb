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
      patch :update, params: { id: id, correspondence: {category: 'freedom_of_information_reuqest', topic: 'prisons', drafter: 'jane_doe@example-drafter.com' } }
    end

    it 'updates the correspondence record' do
      expect(all_correspondence.first.drafter).to eq User.first
    end

  end

end
