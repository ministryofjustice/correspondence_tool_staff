require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:drafter_assignment) { create(:assignment)               }
  let(:unassigned_case)    { create(:case)                     }
  let(:drafter)            { create(:user, roles: ['drafter']) }
  let(:create_assignment_params) do
    {
      case_id: unassigned_case.id,
      assignment: { assignee_id: drafter.id }
    }
  end

  context 'as an anonymous user' do

    describe 'GET new' do
      it 'redirects to sign in page' do
        get :new, params: { case_id: unassigned_case.id }
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
          not_to change { unassigned_case.assignments.count }
      end
    end

    describe 'GET edit' do
      it 'redirects to sign in page' do
        get :edit, params: {
          id: drafter_assignment.id,
          case_id: drafter_assignment.case.id
        }

        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'PATCH accept_or_reject' do
      before do
        patch :accept_or_reject,
          params: {
            id: drafter_assignment.id,
            case_id: drafter_assignment.case.id,
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
          case_id: unassigned_case.id
        }
        expect(response).to render_template(:new)
      end
    end

    describe 'POST create' do
      it 'creates a new assignment for a specific case' do
        expect { post :create, params: create_assignment_params }.
          to change { unassigned_case.assignments.count }.by 1
      end

      it 'redirects to the case list view' do
        post :create, params: create_assignment_params
        expect(response).to redirect_to cases_path
      end
    end

    describe 'GET edit' do
      it 'renders the page for accept / reject assignment' do
        get :edit, params: {
          id: drafter_assignment.id,
          case_id: drafter_assignment.case.id
        }
        expect(response).to render_template(:edit)
      end
    end

    describe 'PATCH accept_or_reject' do
      let(:assigned_case)      { create :assigned_case }
      let(:drafter_assignment) { assigned_case.assignments.detect(&:drafter?) }
      let(:update_params) { {
                              id: drafter_assignment.id,
                              case_id: assigned_case.id,
                            }.merge(assignment_params) }
      let(:assignment_params) { { assignment: { state: 'unknown' } } }

      before do
        allow(Assignment).to receive(:find).
                               with(drafter_assignment.id.to_s).
                               and_return(drafter_assignment)
        allow(Assignment).to receive(:find).
                               with(drafter_assignment.id).
                               and_return(drafter_assignment)
      end

      context 'accepting' do
        let(:assignment_params) { { assignment: { state: 'accepted' } } }

        it 'calls #accept' do
          allow(drafter_assignment).to receive(:accept)
          patch :accept_or_reject, params: update_params
          expect(drafter_assignment).to have_received(:accept)
        end

        it 'updates state' do
          patch :accept_or_reject, params: update_params
          expect(drafter_assignment.reload.state).to eq 'accepted'
        end

        it 'redirects to case detail page' do
          patch :accept_or_reject, params: update_params
          expect(response).to redirect_to case_path assigned_case
        end
      end

      context 'rejecting' do
        let(:message) { |example| "test #{example.description}" }
        let(:assignment_params) do
          {
            assignment: {
              state: 'rejected',
              reasons_for_rejection: message
            }
          }
        end

        it 'calls #reject' do
          allow(drafter_assignment).to receive(:reject)
          patch :accept_or_reject, params: update_params
          expect(drafter_assignment).to have_received(:reject).with(message)
        end

        it 'redirects to case detail page' do
          patch :accept_or_reject, params: update_params
          expect(response).to redirect_to case_path assigned_case
        end

        it 'requires a reason for rejecting' do
          patch :accept_or_reject, params: update_params.merge(
                  assignment: {
                                reasons_for_rejection: '',
                                state: 'rejected'
                              }
                )
          expect(response).to render_template(:edit)
        end
      end

      it 'does not allow unknown states' do
        expect { patch :accept_or_reject, params: update_params }.
          to raise_error(ArgumentError, "'unknown' is not a valid state")
      end

    end
  end
end
