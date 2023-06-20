require "rails_helper"

RSpec.describe Cases::NotesController, type: :controller do
  let!(:team_branston) { find_or_create :team_branston }
  let!(:manager)           { team_branston.users.first }
  let!(:offender_sar_case) { create(:offender_sar_case) }

  describe "POST #create" do
    let(:params) do
      {
        case: {
          message_text: "This is a new message",
        },
        case_id: offender_sar_case.id,
      }
    end

    context "when an anonymous user" do
      it "be redirected to signin if trying to start a new case" do
        post(:create, params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "with offender sar case" do
      let(:params) do
        {
          case: {
            message_text: "This is a new message",
          },
          case_id: offender_sar_case.id,
        }
      end

      context "when a manager" do
        before { sign_in manager }

        it "redirects to case detail page and contains a hash" do
          post(:create, params:)
          expect(response).to redirect_to(case_path(offender_sar_case, anchor: "case-history"))
        end
      end
    end

    context "when message is blank, (user type doesn't matter)" do
      let(:params) do
        {
          case: { message_text: "" },
          case_id: offender_sar_case.id,
        }
      end

      before do
        sign_in manager
        post :create, params:
      end

      it "copies the error to the flash" do
        expect(flash[:case_errors][:message_text]).to eq ["cannot be blank"]
      end

      it "redirects to case detail page and contains a anchor" do
        expect(response)
            .to redirect_to(case_path(offender_sar_case,
                                      anchor: "case-history"))
      end
    end
  end
end
