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

  describe "#system_logs" do
    let!(:system_logs) do
      [
        create(:system_log, created_at: 1.hour.ago),
        create(:system_log, :successful, created_at: 30.minutes.ago),
        create(:email_log, :failed, created_at: 10.minutes.ago),
      ]
    end

    before do
      sign_in admin
      get :system_logs
    end

    it "renders the system_logs view" do
      expect(request.path).to eq("/admin/dashboard/system_logs")
    end

    it "has system logs" do
      expect(assigns(:system_logs)).to match_array(system_logs)
    end

    it "returns logs in descending order by created_at" do
      logs = assigns(:system_logs)
      expect(logs.first.created_at).to be > logs.last.created_at
    end
  end

  describe "#email_logs" do
    let!(:email_logs) do
      [
        create(:email_log, created_at: 1.hour.ago),
        create(:email_log, :successful, created_at: 30.minutes.ago),
        create(:email_log, :failed, created_at: 10.minutes.ago),
      ]
    end

    before do
      create(:system_log) # Non-email log should not appear
      sign_in admin
      get :email_logs
    end

    it "renders the email_logs view" do
      expect(request.path).to eq("/admin/dashboard/email_logs")
    end

    it "has email logs only" do
      expect(assigns(:email_logs)).to match_array(email_logs)
      expect(assigns(:email_logs)).to all(be_a(EmailLog))
    end

    it "returns logs in descending order by created_at" do
      logs = assigns(:email_logs)
      expect(logs.first.created_at).to be > logs.last.created_at
    end
  end
end
