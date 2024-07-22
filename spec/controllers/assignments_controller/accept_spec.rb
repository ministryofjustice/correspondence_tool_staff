require "rails_helper"

RSpec.describe AssignmentsController, type: :controller do # rubocop:disable RSpec/FilePath
  let(:awaiting_responder_case) { create :awaiting_responder_case }
  let(:assignment) { awaiting_responder_case.responder_assignment }
  let(:responding_team) { assignment.team }
  let(:responder) { responding_team.responders.first }
  let(:params) { { case_id: awaiting_responder_case.id, id: assignment.id } }

  describe "GET edit" do
    before do
      sign_in responder
    end

    it "sets @assignment" do
      get(:edit, params:)
      expect(assigns(:assignment)).to eq assignment
    end

    context "when responder is from the wrong team" do
      let(:responding_team) { create :responding_team }
      let(:responder)       { responding_team.responders.first }

      it "does not set @assignment" do
        get(:edit, params:)
        expect(assigns(:assignment)).to eq nil
      end

      it "redirects to the case list view" do
        get(:edit, params:)
        expect(response).to redirect_to case_path(id: params[:case_id])
      end
    end
  end

  describe "PATCH accept_or_reject" do
    let(:accept_or_reject) { "accept" }
    let(:params) { { case_id: awaiting_responder_case.id, id: assignment.id, assignment: { state: "accepted" } } }

    before do
      sign_in responder
    end

    it "sets @assignment" do
      patch(:accept_or_reject, params:)
      expect(assigns(:assignment)).to eq assignment
    end

    context "when accepting" do
      it "accepts the assigment" do
        patch(:accept_or_reject, params:)
        expect(assignment.reload).to be_accepted
      end

      it "redirects to the case list view" do
        patch(:accept_or_reject, params:)
        expect(response).to redirect_to case_path(id: params[:case_id], accepted_now: true)
      end
    end

    context "when rejecting" do
      let(:params) { { case_id: awaiting_responder_case.id, id: assignment.id, assignment: { state: "rejected", reasons_for_rejection: "some reason" } } }

      it "rejects the assigment" do
        patch(:accept_or_reject, params:)
        expect(assignment.reload).to be_rejected
      end

      it "redirects to the case list view" do
        patch(:accept_or_reject, params:)
        expect(response).to redirect_to case_path(id: params[:case_id])
      end
    end

    context "when responder is from the wrong team" do
      let(:responding_team) { create :responding_team }
      let(:responder)       { responding_team.responders.first }

      it "does not set @assignment" do
        patch(:accept_or_reject, params:)
        expect(assigns(:assignment)).to eq nil
      end

      it "redirects to the case list view" do
        patch(:accept_or_reject, params:)
        expect(response).to redirect_to case_path(id: params[:case_id])
      end
    end
  end
end
