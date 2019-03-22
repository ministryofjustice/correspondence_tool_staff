require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let!(:team_dacu)         { find_or_create :team_dacu }
  let!(:manager)           { team_dacu.users.first }
  let!(:approver)          { create :approver }
  let!(:responder)         { find_or_create :foi_responder }
  let!(:another_responder) { create :responder }
  let!(:accepted_case)     { create :accepted_case, responder: responder }
  let!(:closed_case)       { create :closed_case,
                                    :flagged_accepted,
                                    responder: responder,
                                    approver: approver}
  let!(:flagged_case)      { create :accepted_case,
                                    :flagged_accepted,
                                    approver: approver }

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

      it 'allows them to post on a closed case' do
        params[:case_id] = closed_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(closed_case, anchor: 'messages-section'))
      end

      it "does not allow them to post to a case they are not responsible for" do
        sign_in another_responder
        post :create , params: params
        expect(response).to redirect_to(responder_root_path)
      end

      it "sets the case team correctly" do
        post :create , params: params
        expect(controller.send(:case_team).name).to eq('FOI Responding Team')
      end
    end

    context "as a manager" do
      before { sign_in manager }

      it "redirects to case detail page and contains a hash" do
        post :create , params: params
        expect(response).to redirect_to(case_path(accepted_case, anchor: 'messages-section'))
      end

      it 'allows them to post on a closed case' do
        params[:case_id] = closed_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(closed_case, anchor: 'messages-section'))
      end

      it "sets the case team correctly" do
        post :create , params: params
        expect(controller.send(:case_team).name).to eq('Disclosure BMT')
      end
    end

    context "as a approver" do
      before { sign_in approver }

      it "doesn't allow them to post messages to non-trigger cases" do
        post :create , params: params
        expect(response).to redirect_to(approver_root_path)
      end

      it 'allows them to post on a closed case' do
        params[:case_id] = closed_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(closed_case, anchor: 'messages-section'))
      end

      it "redirects to case detail page and contains a anchor" do
        params[:case_id] = flagged_case.id
        post :create , params: params
        expect(response).to redirect_to(case_path(flagged_case, anchor: 'messages-section'))
      end

      it "sets the case team correctly" do
        post :create , params: params
        expect(controller.send(:case_team).name).to match(/Approving Team/)
      end
    end

    context "message is blank, (user type doesn't matter)" do

      before do
        sign_in responder
        params = {
          case_id: accepted_case.id.to_s,
          case: { message_text: '' }
        }
        post :create, params: params
      end

      it "copies the error to the flash" do
        expect(flash[:case_errors][:message_text]).to eq ["can't be blank"]
      end

      it 'redirects to case detail page and contains a anchor' do
        expect(response)
            .to redirect_to(case_path(accepted_case,
                                      anchor: 'messages-section'))
      end
    end

    context "sar case" do
      let(:params) do
        {
          case: {
            message_text: 'This is a new message'
          },
          case_id: sar_case.id
        }
      end

      context "as a manager" do
        let(:sar_case)     { create :sar_case }

        before { sign_in manager }

        it "redirects to case detail page and contains a hash" do
          post :create , params: params
          expect(response).to redirect_to(case_path(sar_case, anchor: 'messages-section'))
        end
      end

      context 'as a multi-role person' do
        let(:sar_case)     { create :awaiting_responder_sar }

        let(:approver_manager)  { create :sar_multi_role_user }

        before { sign_in approver_manager }

        it "creates using the manager role" do
          post :create, params: params
          expect(response).to be_redirect
          expect(sar_case.message_transitions.last.acting_team).to eq(approver_manager.managing_teams.first)
        end
      end
    end
  end
end
