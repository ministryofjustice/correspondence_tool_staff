require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:responding_team)       { unassigned_case.responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:another_responder)     { create :responder, responding_teams: [responding_team] }

  let(:unassigned_case)       { create :offender_sar_complaint }

  let(:assignment)            { unassigned_case.responder_assignment }

  let(:new_user)              { instance_double User,
                                                full_name: 'test' }
  let(:new_assignment)        { instance_double Assignment,
                                                user: new_user}
  let(:service)               { instance_double CaseAssignToTeamMemberService,
                                                call: true,
                                                assignment: new_assignment,
                                                result: :ok }

  let(:params)                { { case_id: unassigned_case.id,
                                   assignment: {
                                     user_id: another_responder.id
                                   }
                                 } }


  describe 'POST execute_assign_to_team_member' do
    before(:each) do
      sign_in responder

      allow(CaseAssignToTeamMemberService).to receive(:new).and_return(service)
      allow(service).to receive(:call).and_return(:ok)
    end

    it 'authorises' do
      expect {
        post :execute_assign_to_team_member, params: params
      } .to require_permission(:can_assign_to_team_member?)
              .with_args(responder, unassigned_case)
    end

    context 'offender sar complaint case' do
      it 'calls UserReassignmentService' do
        post :execute_assign_to_team_member, params: params
        expect(CaseAssignToTeamMemberService).to have_received(:new).with(
                                             kase: unassigned_case.decorate,
                                             role: 'responding',
                                             user: responder,
                                             target_user: another_responder
                                           )
        expect(service).to have_received(:call)
      end

      it 'redirects to new_user_session_path' do
        post :execute_assign_to_team_member, params: params
        expect(response).to redirect_to case_path(id: unassigned_case.id)
      end
    end

  end
end
