require 'rails_helper'

RSpec.describe CorrespondenceController, type: :controller do

  let(:all_correspondence)    { create_list(:correspondence, 5) }
  let(:assigner)              { create(:user) }
  let(:first_correspondence)  { all_correspondence.first }

  before { create(:category, :foi) }

  context "as an anonymous user" do
    describe 'GET index' do
      it "be redirected to signin if trying to list of questions" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET new' do
      it "be redirected to signin if trying to start a new correspondence" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'GET edit' do
      it "be redirected to signin if trying to show a specific correspondence" do
        get :edit, params: { id: first_correspondence }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe 'PATCH update' do
      it "be redirected to signin if trying to update a specific correspondence" do
        patch :update, params: { id: first_correspondence, correspondence: { category_id: create(:category, :gq).id } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Correspondence.first.category.name).to eq 'Freedom of information request'
      end
    end

    describe 'PATCH assign' do
      it "be redirected to signin if trying to assign a specific correspondence" do

        user = create(:user)
        patch :assign, params: { id: first_correspondence, correspondence: { user_id: user } }
        expect(response).to redirect_to(new_user_session_path)
        expect(Correspondence.first.user).to eq nil
      end

    end

    describe 'GET search' do
      it "be redirected to signin if trying to search for a specific correspondence" do
        name = first_correspondence.name
        get :search, params: { search: name }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

  end

  context "as an authenticated user" do

    before { sign_in assigner }

    describe 'GET index' do

      before {
        get :index
      }

      it 'assigns @correspondence' do
        expect(assigns(:correspondence)).to match(all_correspondence)
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end

    describe 'GET new' do
      before {
        get :new
      }

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end
    end

    describe 'POST create' do
      context 'with valid params' do

        let(:params) do
          {
            correspondence: {
              name: 'A. Member of Public',
              postal_address: '',
              email: 'member@public.com',
              email_confirmation: 'member@public.com',
              message: 'An FOI request about prisons and probation',
              received_date_dd: Time.zone.today.day.to_s,
              received_date_mm: Time.zone.today.month.to_s,
              received_date_yyyy: Time.zone.today.year.to_s
            }
          }
        end

        it 'makes a DB entry' do
          expect { post :create, params: params }.
            to change { Correspondence.count }.by 1
        end
      end
    end

    describe 'GET edit' do

      before do
        get :edit, params: { id: first_correspondence }
      end

      it 'assigns @correspondence' do
        expect(assigns(:correspondence)).to eq(Correspondence.first)
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH update' do

      it 'updates the correspondence record' do
        patch :update, params: {
          id: first_correspondence,
          correspondence: { category_id: create(:category, :gq).id }
        }

        expect(Correspondence.find(first_correspondence).category.abbreviation).to eq 'GQ'
      end

      it 'does not overwrite entries with blanks (if the blank dropdown option is selected)' do
        patch :update, params: { id: first_correspondence, correspondence: { category: '' } }
        expect(Correspondence.first.category.abbreviation).to eq 'FOI'
      end
    end

    describe 'PATCH assign' do

      before do
        user = create(:user)
        patch :assign, params: { id: first_correspondence, correspondence: { user_id: user } }
      end

      it 'assigns correspondence to a user' do
        expect(Correspondence.first.drafter).to eq User.last
      end

    end

    describe 'GET search' do

      before do
        get :search, params: { search: first_correspondence.name }
      end

      it 'renders the index template' do
        expect(response).to render_template(:index)
      end
    end
  end
end
