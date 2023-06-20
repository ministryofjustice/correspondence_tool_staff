require "rails_helper"

RSpec.describe Cases::CommissioningDocumentsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request) do
    create(
      :data_request,
      offender_sar_case:,
      cached_num_pages: 10,
      completed: true,
      cached_date_received: Date.yesterday,
    )
  end
  let(:commissioning_document) { create(:commissioning_document, data_request:) }

  let(:params) do
    {
      case_id: data_request.case_id,
      data_request_id: data_request.id,
    }
  end

  before do
    sign_in manager
  end

  describe "#new" do
    before do
      get :new, params:
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it "sets @data_request" do
      expect(assigns(:data_request)).to eq data_request
    end
  end

  describe "#create" do
    context "with valid params" do
      let(:params) do
        {
          case_id: data_request.case_id,
          data_request_id: data_request.id,
          commissioning_document: {
            template_name: "prison",
          },
        }
      end

      it "creates a commissioning_document" do
        expect {
          post :create, params:
        }.to change(CommissioningDocument, :count).by 1
      end

      it "redirects to data request page" do
        post(:create, params:)
        expect(response).to redirect_to(case_data_request_path(offender_sar_case, data_request))
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          case_id: data_request.case_id,
          data_request_id: data_request.id,
          commissioning_document: {
            template_name: "",
          },
        }
      end

      it "creates a commissioning_document" do
        post(:create, params:)
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#update" do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_id: data_request.id,
        commissioning_document: {
          template_name: "probation",
        },
      }
    end

    it "updates a commissioning_document" do
      expect {
        patch :update, params:
      }.to change {
        commissioning_document.reload.template_name
      }.to "probation"
    end

    it "redirects to data request page" do
      patch(:update, params:)
      expect(response).to redirect_to(case_data_request_path(offender_sar_case, data_request))
    end

    context "when attachment exists" do
      let(:attachment) { create(:commissioning_document_attachment) }

      before do
        commissioning_document.update(attachment:)
      end

      it "sets attachment to nil" do
        expect {
          patch :update, params:
        }.to change {
          commissioning_document.reload.attachment
        }.to nil
      end

      it "destroys uploaded file" do
        patch(:update, params:)
        expect { attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#download" do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_id: data_request.id,
      }
    end

    it "downloads the commissioning document" do
      get(:download, params:)
      expect(response.headers["Content-Disposition"]).to match(/filename=".*docx"/)
    end
  end

  describe "#replace" do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_id: data_request.id,
      }
    end

    before do
      get :replace, params:
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it "sets @data_request" do
      expect(assigns(:data_request)).to eq data_request
    end

    it "sets @commissioning_document" do
      expect(assigns(:commissioning_document)).to eq commissioning_document
    end
  end

  describe "#upload" do
    let(:uploader) { double(CommissioningDocumentUploaderService, upload!: nil, result: :ok) }
    let(:uploads_key) { "uploads/10574/commissioning_document/Day1_CATA_211029002_Ole-Out_20230203T1127.docx" }
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_id: data_request.id,
        commissioning_document: {
          upload: [uploads_key],
        },
      }
    end

    before do
      allow(CommissioningDocumentUploaderService).to receive(:new).and_return(uploader)
      post :upload, params:
    end

    it "calls the uploader service" do
      expect(CommissioningDocumentUploaderService).to have_received(:new).with(
        kase: offender_sar_case,
        commissioning_document:,
        current_user: manager,
        uploaded_file: [uploads_key],
      )
      expect(uploader).to have_received(:upload!)
    end
  end

  describe "#send_email" do
    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_id: data_request.id,
      }
    end
    let(:service) { instance_double(CommissioningDocumentEmailService, send!: nil) }

    before do
      allow(CommissioningDocumentEmailService).to receive(:new).and_return(service)
      post :send_email, params:
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it "sets @data_request" do
      expect(assigns(:data_request)).to eq data_request
    end

    it "sets @commissioning_document" do
      expect(assigns(:commissioning_document)).to eq commissioning_document
    end

    it "calls the send email service" do
      expect(service).to receive(:send!)
      post :send_email, params:
    end

    it "redirects to the case page" do
      expect(response).to redirect_to(case_path(offender_sar_case))
    end
  end
end
