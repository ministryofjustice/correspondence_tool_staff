require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let!(:team_dacu)                   { create :team_dacu }
  let!(:manager)                     { team_dacu.users.first }
  let!(:responder)                   { create :responder }
  let!(:another_responder)           { create :responder }
  let!(:responding_team)             { responder.responding_teams.first }
  let!(:disclosure_specialist)       { create :disclosure_specialist }
  let!(:press_officer)               { create :press_officer }
  let!(:team_dacu_disclosure)        { find_or_create :team_dacu_disclosure }
  let!(:assigned_case)               { create :assigned_case, responding_team: responding_team }
  let!(:accepted_case)               { create :accepted_case, responder: responder }
  let!(:press_flagged_case)          { create(:case, :flagged_accepted, :press_office) }
  let!(:pending_dacu_clearance_case)   do
     create :pending_dacu_clearance_case,
            responder: responder
  end

  describe 'POST #create' do

    let(:params) do
      {
        case: {
          message_text: 'This is a new message'
        },
        case_id: accepted_case.id
      }
    end

    context "as an anonymous user" do
      it "be redirected to signin if trying to start a new case" do
        post :create , params: params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a responder" do
      before { sign_in responder }

      it "redirects to case detail page and contains a hash" do
        post :create , params: params
        expect(response).to redirect_to(case_path(accepted_case, anchor: 'messages-section'))
      end

      it "does not allow them to post to a case they are not responsible for" do
        sign_in another_responder
        post :create , params: params
        expect(response).to redirect_to(responder_root_path)
      end

    end

    context "as a manager" do
      before { sign_in manager }

      it "redirects to case detail page and contains a hash" do
        post :create , params: params
        expect(response).to redirect_to(case_path(accepted_case, anchor: 'messages-section'))
      end
    end

    context "as a dacu disclosure" do
      before { sign_in disclosure_specialist }

      it "doesn't allow them to post messages to non-trigger cases" do
        post :create , params: params
        expect(response).to redirect_to(approver_root_path)
      end

      it "redirects to case detail page and contains a hash" do
        params[:case_id] = pending_dacu_clearance_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(pending_dacu_clearance_case, anchor: 'messages-section'))
      end
    end

    context "as Press Office" do
      before { sign_in press_officer }

      it "doesn't allow them to post messages to non-trigger cases" do
        post :create , params: params
        expect(response).to redirect_to(approver_root_path)
      end

      it "redirects to case detail page and contains a hash" do
        params[:case_id] = press_flagged_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(press_flagged_case, anchor: 'messages-section'))
      end
    end
  end
end
