require "rails_helper"

RSpec.describe Cases::LettersController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:offender_sar_case) { create(:offender_sar_case) }
  let!(:letter_template_acknowledgement) { create(:letter_template, :acknowledgement) }
  let!(:letter_template_dispatch) { create(:letter_template, :dispatch) }

  before do
    sign_in manager
  end

  describe "GET #new" do
    context "with valid params" do
      before do
        get :new, params: { case_id: offender_sar_case.id, type: "acknowledgement" }
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "sets @case" do
        expect(assigns(:case)).to eq offender_sar_case
      end

      it "sets @letter_templates" do
        expect(assigns(:letter_templates)).to include letter_template_acknowledgement
        expect(assigns(:letter_templates)).not_to include letter_template_dispatch
      end
    end
  end

  describe "GET #show" do
    context "with valid params" do
      before do
        get :show, params: {
          case_id: offender_sar_case.id,
          type: "acknowledgement",
          letter: { letter_template_id: letter_template_acknowledgement.id },
        }
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "sets @case" do
        expect(assigns(:case)).to eq offender_sar_case
      end

      it "sets @letter" do
        expect(assigns(:letter)).to be_a Letter
      end
    end

    context "word doc with valid params" do
      before do
        get :show, as: :docx, params: {
          case_id: offender_sar_case.id,
          type: "acknowledgement",
          letter: { letter_template_id: letter_template_acknowledgement.id },
        }
      end

      it "generates" do
        expect(response).to have_http_status(:success)
        expect(response.headers["Content-Type"]).to eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=utf-8"
      end
    end

    context "with invalid params" do
      before do
        get :show, params: { case_id: offender_sar_case.id, type: "acknowledgement" }
      end

      it "redirects" do
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
