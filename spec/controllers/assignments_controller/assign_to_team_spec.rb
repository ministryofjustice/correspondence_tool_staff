require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do
  let(:manager)           { create :manager }
  let(:unassigned_case)   { create :case }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:params)            do
    { team_id: responding_team.id.to_s,
      case_id: unassigned_case.id.to_s,
      role: "responding" }
  end

  describe "GET assign_to_team" do
    let(:new_assignment) { instance_double Assignment }
    let(:service)        do
      instance_double CaseAssignResponderService,
                      call: true,
                      assignment: new_assignment,
                      result: :ok
    end

    before do
      allow(CaseAssignResponderService).to receive(:new)
                                             .and_return(service)
      sign_in manager
    end

    it "authorises" do
      expect {
        get :assign_to_team, params:
      }.to require_permission(:can_assign_case?)
                .with_args(manager, unassigned_case)
    end

    it "calls the service" do
      get(:assign_to_team, params:)
      expect(CaseAssignResponderService)
        .to have_received(:new).with kase: unassigned_case,
                                     team: responding_team,
                                     role: "responding",
                                     user: manager
      expect(service).to have_received(:call)
    end

    it "sets @assignment" do
      get(:assign_to_team, params:)
      expect(assigns(:assignment)).to eq new_assignment
    end

    it "redirects to the case list view" do
      get(:assign_to_team, params:)
      expect(response).to redirect_to case_path(id: params[:case_id])
    end

    context "when service fails" do
      before do
        allow(service).to receive(:result).and_return(:could_not_create_assignment)
      end

      it "re-renders the new page" do
        get(:assign_to_team, params:)
        expect(:result).to have_rendered(:new)
      end

      it "sets @assignment" do
        get(:assign_to_team, params:)
        expect(assigns(:assignment)).to eq new_assignment
      end
    end
  end
end
