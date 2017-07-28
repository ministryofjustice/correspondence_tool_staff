require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:manager)           { create :manager }
  let(:unassigned_case)   { create :case }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:params)            { { team_id: responding_team.id.to_s,
                             case_id: unassigned_case.id.to_s,
                             role: 'responding'}}

  describe 'GET assign_to_team' do
    before { sign_in manager }

    it 'authorises' do
      expect{
        get :assign_to_team, params: params
      }.to require_permission(:can_assign_case?)
                .with_args(manager, unassigned_case)
    end

    it 'sets @new_assignment_params' do
      get :assign_to_team, params: params
      expect( assigns(:new_assignment_params))
          .to eq params
    end

    it 'creates a new assignment for a specific case' do
      expect { get :assign_to_team, params: params }.
          to change { unassigned_case.assignments.count }.by 1
    end

    it 'redirects to the case list view' do
      get :assign_to_team, params: params
      expect(response).to redirect_to case_path(id: params[:case_id])
    end

    it 'queues an new assignment mail for later delivery' do
      expect(AssignmentMailer).to receive_message_chain :new_assignment,
                                                        :deliver_later
      get :assign_to_team, params: params
    end

    it 'errors if no team specified' do
      params[:team_id] = nil
      get :assign_to_team, params: params

      expect(assigns(:assignment).errors[:team]).to include("can't be blank")
      expect(response).to render_template(:new)
    end
  end
end
