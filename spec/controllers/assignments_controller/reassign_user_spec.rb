require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do
  let(:responding_team)   { accepted_case.responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:approver)          { create :approver }
  let(:approving_team)    { approver.approving_team }

  let(:accepted_case)     { create :accepted_case }

  let(:assignment)        { accepted_case.responder_assignment }

  describe "GET reassign_user" do
    let(:params) { { case_id: accepted_case.id, id: assignment.id } }

    before do
      sign_in responder
    end

    it "authorises" do
      expect {
        get :reassign_user, params:
      }.to require_permission(:assignments_reassign_user?)
              .with_args(responder, accepted_case)
    end

    it "renders the page" do
      get(:reassign_user, params:)
      expect(response).to render_template :reassign_user
    end

    it "sets the @team_users" do
      get(:reassign_user, params:)
      expect(assigns(:team_users))
        .to eq responding_team.responders.order(:full_name).decorate
    end

    context "when user is both responder and approver" do
      let(:approver_responder) { create :approver_responder }
      let(:approving_team)     { approver_responder.approving_team }
      let(:accepted_case)      do
        create :accepted_case, :flagged_accepted,
               approver: approver_responder,
               approving_team:
      end
      let(:assignment) { accepted_case.approver_assignments.first }

      it "uses the assignment_id param to set @team_users" do
        get(:reassign_user, params:)
        expect(assigns(:team_users))
          .to eq approving_team.approvers.order(:full_name).decorate
      end
    end
  end
end
