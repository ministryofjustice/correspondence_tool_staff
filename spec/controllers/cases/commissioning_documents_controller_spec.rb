require "rails_helper"

RSpec.describe Cases::CommissioningDocumentsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area, offender_sar_case: }

  before do
    sign_in manager
  end

  # Commissioning Document entries are created automatically when a DataRequestArea is created.
  # However there are legacy records without any CommissionDocument which may be accessed for posterity.
  describe "#download" do
    context "when the commissioning document exists" do
      let(:commissioning_document) { create(:commissioning_document, data_request_area:) }

      let(:params) do
        {
          id: commissioning_document.id,
          case_id: offender_sar_case.id,
          data_request_area_id: data_request_area.id,
        }
      end

      it "downloads the commissioning document" do
        get(:download, params:)
        expect(response.headers["Content-Disposition"]).to match(/filename=".*docx"/)
      end
    end

    context "when the commissioning document does not exist" do
      before do
        data_request_area.update!(commissioning_document: nil)
      end

      let(:params) do
        {
          id: "non-existent-id",
          case_id: offender_sar_case.id,
          data_request_area_id: data_request_area.id,
        }
      end

      it "does not attempt to download and redirects with an alert" do
        get(:download, params:)
        expect(response).to redirect_to(case_data_request_area_path(offender_sar_case, data_request_area))
        expect(flash[:alert]).to eq(I18n.t("cases.commissioning_documents.not_found"))
      end
    end
  end

  describe "#send_email" do
    let(:commissioning_document) { create(:commissioning_document, data_request_area:) }

    let(:params) do
      {
        id: commissioning_document.id,
        case_id: offender_sar_case.id,
        data_request_area_id: data_request_area.id,
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

    it "sets @data_request_area" do
      expect(assigns(:data_request_area)).to eq data_request_area
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
