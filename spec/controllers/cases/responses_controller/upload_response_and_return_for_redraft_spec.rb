require "rails_helper"

describe Cases::ResponsesController, type: :controller do
  let(:responded_trigger_case) { create :pending_dacu_clearance_case }
  let(:approver)               { responded_trigger_case.approvers.first }

  describe "upload_response_and_return_for_redraft" do
    let(:params) do
      {
        case_id: responded_trigger_case.id,
        response_action: "upload_response_and_return_for_redraft",
      }
    end

    before do
      sign_in approver
    end

    it "authorises and renders" do
      expect {
        get(:new, params:)
      }.to require_permission(:upload_response_and_return_for_redraft?)
        .with_args(approver, responded_trigger_case)

      expect(response).to have_http_status(:ok)
      expect(response).to have_rendered(:upload_response_and_return_for_redraft)
      expect(assigns(:case)).to eq responded_trigger_case.decorate
      expect(assigns(:action)).to eq(:upload_response_and_return_for_redraft)
      expect(assigns(:approval_action)).to eq("approve")

      settings = assigns(:settings)
      expect(settings[:policy]).to eq(:upload_response_and_return_for_redraft?)
    end
  end

  describe "execute_upload_response_and_return_for_redraft" do
    let(:uploads_key) { "uploads/#{responded_trigger_case.id}/responses/#{Faker::Internet.slug}.jpg" }
    let(:params) do
      {
        case_id: responded_trigger_case.id,
        type: "response",
        uploaded_files: [uploads_key],
        draft_compliant: "yes",
        response_action: "upload_response_and_return_for_redraft",
      }
    end

    let(:service) do
      instance_double(
        ResponseUploaderService,
        upload!: true,
        result: :ok,
      )
    end

    before do
      sign_in approver
      allow(ResponseUploaderService).to receive(:new).and_return(service)
    end

    it "authorizes" do
      expect {
        post :create, params:
      }.to require_permission(:upload_response_and_return_for_redraft?)
          .with_args(approver, responded_trigger_case)
    end

    it "calls the response upload service" do
      post(:create, params:)
      expect(ResponseUploaderService).to have_received(:new).with(
        hash_including(
          current_user: approver,
          kase: responded_trigger_case,
          action: "upload-redraft",
          upload_comment: nil,
          uploaded_files: [uploads_key],
          is_compliant: true,
        ),
      )

      expect(service).to have_received(:upload!)
    end

    context "when successful action" do
      it "flashes a notification" do
        post(:create, params:)
        expect(flash[:notice])
          .to eq "You have uploaded the response for this case."
      end

      it "redirects to case detail page" do
        post(:create, params:)
        expect(response).to redirect_to(case_path(responded_trigger_case))
      end

      it "sets permitted events" do
        post(:create, params:)
        expect(assigns[:permitted_events]).not_to be_nil
      end
    end

    context "when uploaded_files is blank" do
      before do
        allow(service).to receive(:result).and_return(:blank)
      end

      it "flashes an error" do
        post(:create, params:)
        expect(flash[:alert])
          .to eq "Please select the file(s) you used in your response."
      end

      it "renders the upload_response_and_return_for_redraft page" do
        post(:create, params:)
        expect(response).to have_rendered(:upload_response_and_return_for_redraft)
      end
    end

    context "when error in uploader service" do
      before do
        allow(service).to receive(:result).and_return(:error)
      end

      it "flashes an error" do
        post(:create, params:)
        expect(flash[:alert]).to eq "Errors detected with uploaded files."
      end

      it "renders the upload_response_and_return_for_redraft page" do
        post(:create, params:)
        expect(response).to have_rendered(:upload_response_and_return_for_redraft)
      end
    end
  end
end
