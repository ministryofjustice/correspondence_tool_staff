require "rails_helper"

RSpec.describe Cases::CommissioningDocumentsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area, offender_sar_case: }
  let(:commissioning_document) { create(:commissioning_document, data_request_area:) }

  let(:params) do
    {
      case_id: data_request_area.case_id,
      data_request_area_id: data_request_area.id,
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
        data_request_area_id: data_request_area.id,
      }
    end

    context "when case is not destroyed" do
      it "downloads the commissioning document" do
        get(:download, params:)
        expect(response.headers["Content-Disposition"]).to match(/filename=".*docx"/)
      end
    end

    context "when case is destroyed" do
      let(:offender_sar_case) do
        create(
          :offender_sar_case,
          :closed,
          date_responded: Time.zone.today,
          retention_schedule:
            RetentionSchedule.new(
              state: :to_be_anonymised,
              planned_destruction_date: Time.zone.local(2025, 5, 15),
            ),
        )
      end

      before do
        offender_sar_case.retention_schedule.anonymise!
      end

      it "commissioning document is not found" do
        get(:download, params:)

        expect(response).to have_http_status(410)
        expect(response.body).to include("The content or document you requested is not available")
      end
    end
  end

  describe "#send_email" do
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
