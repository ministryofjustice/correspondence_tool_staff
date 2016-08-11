require 'rails_helper'

RSpec.describe CorrespondenceController, type: :controller do

  let(:all_correspondence) { create_list(:correspondence, 5) }
  let(:assigner) { create(:user) }

  context "anonymous user" do

    context ' GET index' do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'GET edit' do
      it "be redirected to signin if trying to show a specific correspondence" do
        id = all_correspondence.first.id
        get :edit, params: { id: id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'PATCH update' do
      it "be redirected to signin if trying to update a specific correspondence" do
        id = all_correspondence.first.id
        patch :update, params: { id: id, correspondence: { category_id: create(:category).id, topic: 'courts' } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Correspondence.first.topic).to eq 'prisons'
      end
    end

    context 'PATCH assign' do
      it "be redirected to signin if trying to assign a specific correspondence" do

        id = all_correspondence.first.id
        user_id = create(:user)
        patch :assign, params: { id: id, correspondence: { user_id: user_id } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Correspondence.first.user).to eq nil
      end

    end

    context 'GET search' do
      it "be redirected to signin if trying to search for a specific correspondence" do
        name = all_correspondence.first.name
        get :search, params: { search: name }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

  end

  context "Staff user" do
    context 'GET index' do

      before {
        sign_in assigner
        get :index
      }

      it 'assigns @correspondence' do
        expect(assigns(:correspondence)).to match(all_correspondence)
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    context 'GET edit' do

      before do
        sign_in assigner
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
        sign_in assigner
        id = all_correspondence.first.id
        patch :update, params: { id: id, correspondence: { category: create(:category), topic: 'courts' } }
      end

      it 'updates the correspondence record' do
        expect(Correspondence.first.topic).to eq 'courts'
      end

      it 'does not overwrite entries with blanks (if the blank dropdown option is selected)' do
        id = all_correspondence.first.id
        patch :update, params: { id: id, correspondence: { category: '', topic: 'courts' } }
        expect(Correspondence.first.category.name).to eq 'freedom_of_information_request'
      end
    end

    context 'PATCH assign' do

      before do
        sign_in assigner
        id = all_correspondence.first.id
        user_id = create(:user)
        patch :assign, params: { id: id, correspondence: { user_id: user_id } }
      end

      it 'assigns correspondence to a user' do
        expect(Correspondence.first.drafter).to eq User.last
      end

    end

    context 'GET search' do

      before do
        sign_in assigner
        name = all_correspondence.first.name
        get :search, params: { search: name }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end
  end
end
