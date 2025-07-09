require "rails_helper"

RSpec.describe Cases::ICOSARController, type: :controller do
  before do
    sign_in approver
  end

  let(:approved_sar_ico) { create :approved_ico_sar_case }
  let(:approving_team) { approved_sar_ico.approving_teams.first }
  let(:approver) { approving_team.users.first }
  let(:params) do
    {
      id: approved_sar_ico.id,
      ico: { sar_complaint_outcome: "bau_ico_informed" },
    }
  end

  describe "#record_complaint_outcome" do
    it "authorizes" do
      expect {
        get :record_complaint_outcome, params: { id: approved_sar_ico.id }
      }.to require_permission(:can_set_outcome?)
        .with_args(approver, approved_sar_ico)
    end

    it "sets @case" do
      get :record_complaint_outcome, params: { id: approved_sar_ico.id }
      expect(assigns(:case)).to eq approved_sar_ico
    end

    it "renders view" do
      get :record_complaint_outcome, params: { id: approved_sar_ico.id }
      expect(response).to render_template("cases/ico/sar/record_complaint_outcome")
    end
  end

  describe "#confirm_record_complaint_outcome" do
    it "authorizes" do
      expect {
        patch(:confirm_record_complaint_outcome, params:)
      }.to require_permission(:can_set_outcome?)
        .with_args(approver, approved_sar_ico)
    end

    it "sets @case" do
      patch(:confirm_record_complaint_outcome, params:)
      expect(assigns(:case)).to eq approved_sar_ico
    end

    it "sets the complaint outcome" do
      patch(:confirm_record_complaint_outcome, params:)

      approved_sar_ico.reload
      expect(approved_sar_ico.sar_complaint_outcome).to eq "bau_ico_informed"
    end

    it "sets case as responded" do
      stub_find_case(approved_sar_ico)
      expect(approved_sar_ico).to receive(:respond).with(approver)
      patch(:confirm_record_complaint_outcome, params:)
    end

    it "redirects to case details page" do
      patch(:confirm_record_complaint_outcome, params:)
      expect(response).to redirect_to(case_path(approved_sar_ico))
    end

    context "when params are invalid" do
      let(:params) do
        {
          id: approved_sar_ico.id,
          ico: { sar_complaint_outcome: "invalid_reason" },
        }
      end

      it "re-renders the template" do
        patch(:confirm_record_complaint_outcome, params:)
        expect(response).to render_template("cases/ico/sar/record_complaint_outcome")
      end
    end
  end
end
