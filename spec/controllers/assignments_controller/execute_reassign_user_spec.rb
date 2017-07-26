require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:responding_team)   { accepted_case.responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:another_responder) { create :responder, responding_teams: [responding_team] }

  let(:accepted_case) { create :accepted_case }

  let(:assignment) { accepted_case.responder_assignment }

  let(:service)    { instance_double UserReassignmentService }

  let(:params)     { { case_id: accepted_case.id,
                       id: assignment.id,
                       assignment: {
                         user_id: another_responder.id
                       }
                     } }


  describe 'PATCH execute_reassign_user' do
    before(:each) do
      sign_in responder

      allow(UserReassignmentService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(:ok)
    end

    it 'authorises' do
      expect {
        patch :execute_reassign_user, params: params
      } .to require_permission(:assignments_execute_reassign_user?)
              .with_args(responder, accepted_case)
    end


    it 'calls UserReassignmentService' do
      patch :execute_reassign_user, params: params
      expect(UserReassignmentService).to have_received(:new).with(
                                           acting_user: responder,
                                           target_user: another_responder,
                                           assignment: assignment
                                         )
      expect(service).to have_received(:call)
    end

    it 'redirects to new_user_session_path' do
      patch :execute_reassign_user, params: params
      expect(response).to redirect_to case_path(id: accepted_case.id)
    end
  end
end
