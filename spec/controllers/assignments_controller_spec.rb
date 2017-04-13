require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:assigned_case)   { create :assigned_case }
  let(:assignment)      { assigned_case.responder_assignment }
  let(:unassigned_case) { create :case }
  let(:responding_team) { assigned_case.responding_team }
  let(:responder)       { responding_team.responders.first }
  let(:create_assignment_params) do
    {
      case_id: unassigned_case.id,
      assignment: { team_id: responding_team.id }
    }
  end
  let(:accept_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: { state: 'accepted' }
    }
  end
  let(:reject_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: {
        state: 'rejected',
        reasons_for_rejection: rejection_message,
      },
    }
  end
  let(:rejection_message) do |_example|
    'rejection test #{example.description}'
  end
  let(:unknown_assignment_params) do
    {
      id: assignment.id,
      case_id: assigned_case.id,
      assignment: { state: 'unknown' },
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
          id: assignment.id,
          case_id: assignment.case.id
        }

        expect(response).to redirect_to new_user_session_path
      end
    end

    describe 'PATCH accept_or_reject' do
      before do
        patch :accept_or_reject,
          params: {
            id: assignment.id,
            case_id: assignment.case.id,
            assignment: { state: 'accepted' }
          }
      end

      it 'does not update state' do
        expect(assignment.state).to eq 'pending'
      end

      it 'redirects to sign in page' do
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  context 'as an authenticated assigner' do
    before { sign_in create(:manager) }

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
        expect(response).to redirect_to case_path(id: create_assignment_params[:case_id])
      end

      it 'queues an new assignment mail for later delivery' do
        expect(AssignmentMailer).to receive_message_chain(:new_assignment, :deliver_later)
        post :create, params: create_assignment_params
      end

      it 'errors if no team specified' do
        post :create, params:  {'commit' => 'Create and assign case', 'case_id' => unassigned_case.id }
        expect(assigns(:assignment).errors[:team]).to include("can't be blank")
        expect(response).to render_template(:new)
      end
    end

    describe 'GET edit' do
      it 'does not render the page for accept / reject assignment' do
        get :edit, params: {
          id: assignment.id,
          case_id: assignment.case.id
        }
        expect(response).not_to render_template(:edit)
      end
    end

    describe 'PATCH accept_or_reject' do
      before do
        allow(Assignment).to receive(:find).
                               with(assignment.id.to_s).
                               and_return(assignment)
        allow(Assignment).to receive(:find).
                               with(assignment.id).
                               and_return(assignment)
      end

      context 'accepting' do
        it 'does not call #accept' do
          allow(assignment).to receive(:accept)
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment).not_to have_received(:accept)
        end

        it 'does not update state' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment.reload.state).to eq 'pending'
        end

        it 'redirects to application root' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(response).to redirect_to authenticated_root_path
        end
      end

      context 'rejecting' do
        it 'does not call #reject' do
          allow(assignment).to receive(:reject)
          patch :accept_or_reject, params: reject_assignment_params
          expect(assignment).not_to have_received(:reject)
                                      .with(rejection_message)
        end

        it 'redirects to application root' do
          patch :accept_or_reject, params: reject_assignment_params
          expect(response).to redirect_to authenticated_root_path
        end
      end
    end
  end

  context 'as an authenticated responder' do
    let(:assignment_params) { { assignment: { state: 'accept' } } }

    before { sign_in responder }

    describe 'GET new' do
      it 'does not render the page for assignment' do
        get :new, params: {
          case_id: unassigned_case.id
        }
        expect(response).not_to render_template(:new)
      end
    end

    describe 'POST create' do
      it 'does not create a new assignment for a specific case' do
        expect { post :create, params: create_assignment_params }.
          not_to change { unassigned_case.assignments.count }
      end

      it 'redirects to the application root' do
        post :create, params: create_assignment_params
        expect(response).to redirect_to authenticated_root_path
      end
    end

    describe 'PATCH accept_or_reject' do
      before do
        allow(Assignment).to receive(:find).
                               with(assignment.id.to_s).
                               and_return(assignment)
        allow(Assignment).to receive(:find).
                               with(assignment.id).
                               and_return(assignment)
      end

      context 'accepting' do
        let(:assignment_params) { { assignment: { state: 'accepted' } } }

        it 'calls #accept' do
          allow(assignment).to receive(:accept)
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment).to have_received(:accept)
        end

        it 'updates state' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(assignment.reload.state).to eq 'accepted'
        end

        it 'redirects to case detail page' do
          patch :accept_or_reject, params: accept_assignment_params
          expect(response).to redirect_to(
                                case_path assigned_case,
                                          accepted_now: true
                              )
        end
      end

      context 'rejecting' do
        it 'calls #reject' do
          allow(assignment).to receive(:reject)
          patch :accept_or_reject, params: reject_assignment_params
          expect(assignment).to have_received(:reject)
                                  .with(responder, rejection_message)
        end

        it 'redirects to show_rejected page' do
          patch :accept_or_reject, params: reject_assignment_params
          expect(response).to redirect_to(
                                 case_assignments_show_rejected_path(
                                   assigned_case,
                                   rejected_now: true
                                 )
                               )
        end

        it 'requires a reason for rejecting' do
          patch :accept_or_reject, params: reject_assignment_params.merge(
                  assignment: {
                                reasons_for_rejection: '',
                                state: 'rejected'
                              }
                )
          expect(response).to render_template(:edit)
        end

      end

      it 'does not allow unknown states' do
        expect { patch :accept_or_reject, params: unknown_assignment_params }.
          to raise_error(ArgumentError, "'unknown' is not a valid state")
      end
    end
  end
end
