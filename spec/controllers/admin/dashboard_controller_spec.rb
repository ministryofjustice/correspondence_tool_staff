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
    let(:event) do
      Events::EmailSent.new(
        data: {
          recipient: "test@test.com",
          subject: "Subject Access Request - 12345",
          category: "commissioning_document",
          email_type: "commissioning_email",
          recipient_type: "external",
          case_number: "12345",
        },
      )
    end
    let(:failed_event) do
      Events::EmailFailed.new(
        data: {
          recipient: "test@test.com",
          subject: "Subject Access Request - 12345",
          category: "commissioning_document",
          email_type: "commissioning_email",
          recipient_type: "external",
          case_number: "12345",
          status: "permanent-failure",
          notify_id: "notify-123",
        },
      )
    end
    let(:event_store) { instance_double(RailsEventStore::Client) }
    let(:reader) { instance_double(RailsEventStore::ReadSpecification) }

    before do
      sign_in admin
      allow(RailsEventStore::Client).to receive(:new).and_return(event_store)
      allow(event_store).to receive(:read).and_return(reader)
      allow(reader).to receive(:backward).and_return(reader)
      allow(reader).to receive(:newer_than_or_equal).and_return(reader)
      allow(reader).to receive(:to_a).and_return([failed_event, event])
      get :events
    end

    it "renders the events page" do
      expect(request.path).to eq("/admin/dashboard/events")
    end

    it "shows structured email event details" do
      expect(response.body).to include("Email sent")
      expect(response.body).to include("Email failed")
      expect(response.body).to include("test@test.com")
      expect(response.body).to include("Subject Access Request - 12345")
      expect(response.body).to include("Commissioning document | Commissioning email | External | Case 12345")
      expect(response.body).to include("Commissioning document | Commissioning email | Permanent failure | External | Case 12345 | Notify notify-123")
    end
  end
end
