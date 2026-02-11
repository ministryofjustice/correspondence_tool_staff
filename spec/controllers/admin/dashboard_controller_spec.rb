require "rails_helper"

describe Admin::DashboardController do
  let(:admin)         { create :admin }
  let(:manager)       { create :manager }
  let!(:search_query) { create :search_query }
  let!(:list_query)   { create :list_query }

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
end
