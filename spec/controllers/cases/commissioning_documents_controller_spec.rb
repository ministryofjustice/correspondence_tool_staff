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
      cached_date_received: Time.zone.yesterday,
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
