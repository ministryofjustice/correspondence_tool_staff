require "rails_helper"

describe Admin::DashboardController do
  let(:admin)         { create :admin }
  let(:manager)       { create :manager }
  let!(:search_query) { create :search_query }
  let!(:list_query)   { create :list_query }

  let!(:personal_information_requests) do
    [
      create(:personal_information_request),
      create(:personal_information_request, :deleted),
      create(:personal_information_request, :processed),
    ]
  end

  describe "#feedback" do
    before do
      sign_in admin
      get :feedback
    end

    it "renders the index view" do
      expect(request.path).to eq("/admin/dashboard/feedback")
    end
  end

  describe "#feedback_year" do
    before do
      sign_in admin
      get :feedback_year, params: { year: 2023 }
    end

    it "renders the show view" do
      expect(request.path).to eq("/admin/dashboard/feedback/2023")
    end
  end

  describe "#list_queries" do
    before do
      sign_in admin
      get :list_queries
    end

    it "renders the index view" do
      expect(request.path).to eq("/admin/dashboard/list_queries")
    end

    it "has search queries" do
      expect(controller.queries).to eq [list_query]
    end
  end

  describe "#search_queries" do
    before do
      sign_in admin
      get :search_queries
    end

    it "renders the search_queries view" do
      expect(request.path).to eq("/admin/dashboard/search_queries")
    end

    it "has search queries" do
      expect(controller.queries).to eq [search_query]
    end
  end

  describe "#system" do
    before do
      sign_in admin
      get :system
    end

    it "renders the system view" do
      expect(request.path).to eq("/admin/dashboard/system")
    end

    it "has Git version SHA" do
      git_sha = assigns(:version)
      expect(git_sha).to be_present
      expect(git_sha).to eq Settings.git_commit
    end
  end

  describe "#bank_holidays" do
    before { sign_in admin }

    it "renders the page" do
      get :bank_holidays
      expect(response).to have_http_status(:ok)
      expect(request.path).to eq("/admin/dashboard/bank-holidays")
    end
  end

  describe "#load_bank_holidays" do
    before { sign_in admin }

    context "when the service succeeds" do
      it "redirects to bank holidays page with a notice" do
        allow(BankHolidaysService).to receive(:new)
        post :load_bank_holidays
        expect(response).to redirect_to(admin_dashboard_bank_holidays_path)
        expect(flash[:notice]).to eq("Bank holidays loaded successfully.")
      end
    end

    context "when the service raises an error" do
      it "redirects to bank holidays page with an alert" do
        allow(BankHolidaysService).to receive(:new).and_raise(StandardError, "connection failed")
        post :load_bank_holidays
        expect(response).to redirect_to(admin_dashboard_bank_holidays_path)
        expect(flash[:alert]).to eq("Failed to load bank holidays: connection failed")
      end
    end
  end

  describe "#personal_information_requests" do
    before do
      sign_in admin
      get :personal_information_requests
    end

    it "renders the personal_information_requests view" do
      expect(request.path).to eq("/admin/dashboard/personal_information_requests")
    end

    it "has personal information requests" do
      expect(controller.personal_information_requests).to match_array(personal_information_requests)
    end
  end

  describe "#events" do
    let(:email_sent_event) do
      Events::EmailSent.build(
        recipient: "test@test.com",
        subject: "Subject Access Request - 12345",
        category: "commissioning_document",
        email_type: "commissioning_email",
        recipient_type: "external",
        case_number: "12345",
      )
    end

    let(:email_failed_event) do
      Events::EmailFailed.build(
        recipient: "test@test.com",
        subject: "Subject Access Request - 12345",
        category: "commissioning_document",
        email_type: "commissioning_email",
        recipient_type: "external",
        case_number: "12345",
        status: "permanent-failure",
        notify_id: "notify-123",
      )
    end

    let(:rpi_failed_event) do
      Events::RpiUnprocessed.build(
        personal_information_request_id: 1,
        submission_id: "submission-123",
        schema: "1",
        error_message: "Failed to process RPI",
      )
    end

    before do
      Rails.configuration.event_store.publish(email_sent_event, stream_name: "email_events")
      Rails.configuration.event_store.publish(email_failed_event, stream_name: "email_events")
      Rails.configuration.event_store.publish(rpi_failed_event, stream_name: "rpi_events")

      sign_in admin
      get :events
    end

    it "renders the events view" do
      expect(request.path).to eq("/admin/dashboard/events")
    end

    it "has events" do
      expect(assigns(:email_failed_events_count)).to eq 1
      expect(assigns(:rpi_failed_events_count)).to eq 1
    end
  end
end
