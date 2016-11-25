require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:drafter_assignment)        { create(:assignment)               }
  let(:unassigned_correspondence) { create(:correspondence)           }
  let(:drafter)                   { create(:user, roles: ['drafter']) }
  let(:create_assignment_params) do
    {
      correspondence_id: unassigned_correspondence.id,
      assignment: { assignee_id: drafter.id }
    }
  end

  context 'as an anonymous user' do

    describe 'GET new' do
      it 'redirects to sign in page' do
        get :new, params: { correspondence_id: unassigned_correspondence.id }
        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'POST create' do
      it 'redirects to sign in page' do
        post :create, params: create_assignment_params

        expect(response).to redirect_to new_user_session_path
      end

      it 'does not create a new assignment' do
        expect { post :create, params: create_assignment_params }.
          not_to change { unassigned_correspondence.assignments.count }
      end
    end

    describe 'GET edit' do
      it 'redirects to sign in page' do
        get :edit, params: {
          id: drafter_assignment.id,
          correspondence_id: drafter_assignment.correspondence.id
        }

        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'PATCH update' do
      before do
        patch :update,
          params: {
            id: drafter_assignment.id,
            correspondence_id: drafter_assignment.correspondence.id,
            assignment: { state: 'accepted' }
          }
      end

      it 'does not update state' do
        expect(drafter_assignment.state).to eq 'pending'
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  context 'as an authenticated user' do
    before { sign_in create(:user, roles: ['assigner']) }

    describe 'GET new' do
      it 'renders the page for assignment' do
        get :new, params: {
          correspondence_id: unassigned_correspondence.id
        }
        expect(response).to render_template(:new)
      end
    end

    describe 'POST create' do
      it 'creates a new assignment for a specific item of correspondence' do
        expect { post :create, params: create_assignment_params }.
          to change { unassigned_correspondence.assignments.count }.by 1
      end

      it 'redirects to the correspondence list view' do
        post :create, params: create_assignment_params
        expect(response).to redirect_to correspondence_index_path
      end
    end

    describe 'GET edit' do
      it 'renders the page for accept / reject assignment' do
        get :edit, params: {
          id: drafter_assignment.id,
          correspondence_id: drafter_assignment.correspondence.id
        }
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH update' do
      before do
        patch :update,
          params: {
            id: drafter_assignment.id,
            correspondence_id: drafter_assignment.correspondence.id,
            assignment: { state: 'accepted' }
          }
      end

      it 'updates state' do
        expect(drafter_assignment.reload.state).to eq 'accepted'
      end

      it 'redirects to correspondence detail page' do
        expect(response).to redirect_to('correspondence#show')
      end
    end
  end
end
