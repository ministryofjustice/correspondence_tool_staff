require "rails_helper"

describe Cases::ResponsesController, type: :controller do
  let(:responder)     { find_or_create :foi_responder }
  let(:accepted_case) { create(:accepted_case) }

  before do
    sign_in responder
  end

  describe "upload_responses" do
    it "authorises and renders" do
      expect {
        get :new,
            params: {
              case_id: accepted_case.id,
              response_action: "upload_responses",
            }
      }.to require_permission(:upload_responses?).with_args(responder, accepted_case)

      expect(response).to have_http_status(:ok)
      expect(response).to have_rendered("cases/responses/upload_responses")
      expect(assigns(:action)).to eq(:upload_responses)
      expect(assigns(:approval_action)).to eq(nil)

      settings = assigns(:settings)
      expect(settings[:policy]).to eq(:upload_responses?)
    end
  end

  describe "execute_upload_responses" do
    let(:uploads_key) { "uploads/#{accepted_case.id}/responses/#{Faker::Internet.slug}.jpg" }
    let(:response_uploader) { double ResponseUploaderService, upload!: nil, result: :ok }
    let(:flash)             { MockFlash.new(action_params: "upload") }
    let(:params) do
      {
        case_id: accepted_case,
        response_action: "upload_responses",
        uploaded_files: [uploads_key],
      }
    end

    let(:flash)             { MockFlash.new(action_params: "upload") }
    let(:response_uploader) { double ResponseUploaderService, upload!: nil, result: :ok }

    it "authorises" do
      expect {
        post :create, params:
      }.to require_permission(:upload_responses?)
             .with_args(responder, accepted_case)
    end

    context "when files specified without a comment" do
      before do
        allow_any_instance_of(CasesController)
          .to receive(:flash).and_return(flash)

        allow(ResponseUploaderService)
          .to receive(:new).and_return(response_uploader)

        post :create, params:
      end

      it "calls ResponseUploaderService" do
        expect(ResponseUploaderService).to have_received(:new).with(
          kase: accepted_case,
          current_user: responder,
          action: "upload",
          uploaded_files: [uploads_key],
          upload_comment: nil,
          bypass_message: nil,
          bypass_further_approval: false,
          # action 'upload' ignores the is_compliant flag
          is_compliant: false,
        )
        expect(response_uploader).to have_received(:upload!)
      end

      it "redirects to the case details page" do
        expect(response).to redirect_to(case_path(accepted_case))
      end

      it "sets a flash message" do
        expect(request.flash[:notice]).to eq "You have uploaded the response for this case."
      end
    end

    context "when no files specified" do
      before do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        allow(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        allow(response_uploader).to receive(:result).and_return(:blank)
      end

      it "re-renders the page" do
        post(:create, params:)
        expect(response).to have_rendered(:upload_responses)
      end

      it "sets the flash alert" do
        post(:create, params:)
        expect(request.flash[:alert]).to eq "Please select the file(s) you used in your response."
      end
    end

    context "when there is an upload error" do
      before do
        allow_any_instance_of(CasesController).to receive(:flash).and_return(flash)
        allow(ResponseUploaderService).to receive(:new).and_return(response_uploader)
        allow(response_uploader).to receive(:result).and_return(:error)
      end

      it "re-renders the page if there is an upload error" do
        post(:create, params:)
        expect(response).to have_rendered(:upload_responses)
      end

      it "sets the flash alert" do
        post(:create, params:)
        expect(request.flash[:alert]).to eq "Errors detected with uploaded files."
      end
    end
  end
end
