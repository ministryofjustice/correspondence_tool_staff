require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do # rubocop:disable RSpec/FilePath
  let(:responding_team) { unassigned_case.responding_team }
  let(:responder) { responding_team.responders.first }
  let(:unassigned_case) { create :offender_sar_complaint }

  describe "GET assign_to_team_member" do
    let(:params) { { case_id: unassigned_case.id } }

    before do
      sign_in responder
    end

    it "authorises" do
      expect {
        get :assign_to_team_member, params:
      }.to require_permission(:can_assign_to_team_member?)
              .with_args(responder, unassigned_case)
    end

    it "renders the page" do
      get(:assign_to_team_member, params:)
      expect(response).to render_template :assign_to_team_member
    end

    it "sets the @team_users" do
      get(:assign_to_team_member, params:)
      expect(assigns(:current_user)).to eq responder
      expect(assigns(:case)).to eq unassigned_case
      expect(assigns(:team_users))
        .to eq responder.case_team(unassigned_case).users.order(:full_name)
    end
  end

  describe "GET assign_to_vetter" do
    let(:unassigned_case) { create :offender_sar_case, current_state: :ready_for_vetting }
    let(:params) { { case_id: unassigned_case.id } }

    before do
      sign_in responder
    end

    it "authorises" do
      expect {
        get :assign_to_vetter, params:
      }.to require_permission(:can_assign_to_team_member?).with_args(responder, unassigned_case)
    end

    it "renders the page" do
      get(:assign_to_vetter, params:)
      expect(response).to render_template :assign_to_vetter
    end

    it "sets the @team_users" do
      get(:assign_to_vetter, params:)
      expect(assigns(:current_user)).to eq responder
      expect(assigns(:case)).to eq unassigned_case
      expect(assigns(:team_users))
        .to eq responder.case_team(unassigned_case).users.order(:full_name)
    end
  end
end
