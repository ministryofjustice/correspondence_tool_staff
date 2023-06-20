require "rails_helper"

describe "cases/searches/show.html.slim", type: :view do
  def allow_case_policy(policy_name)
    policy = double("Pundit::Policy", policy_name => true)
    allow(view).to receive(:policy).with(:case).and_return(policy)
  end

  def disallow_case_policy(policy_name)
    policy = double("Pundit::Policy", policy_name => false)
    allow(view).to receive(:policy).with(:case).and_return(policy)
  end

  let(:closed_case) { create(:closed_case) }

  context "when no search query" do
    before do
      assign(:cases, [])
      assign(:query, build_stubbed(:search_query, search_text: ""))
      assign(:action_url, "/cases/search")
      render
      cases_search_page.load(rendered)
    end

    it "shows a search field" do
      expect(cases_search_page).to have_search_query
    end

    it "does not display the filters" do
      expect(cases_search_page).to have_no_case_filters
    end

    it "does not display number of results found" do
      expect(cases_search_page).to have_no_search_results_count
      expect(cases_search_page).to have_no_download_cases_link
      expect(cases_search_page).to have_no_found_no_results_copy
    end
  end

  context "when no results are found" do
    before do
      assign(:query, create(:search_query, search_text: "no search results"))
      assign(:cases, [])
      assign(:action_url, "/cases/search")
      render
      cases_search_page.load(rendered)
    end

    it "shows a search field" do
      expect(cases_search_page).to have_search_query
    end

    it "does not display the filters" do
      expect(cases_search_page).to have_no_case_filters
    end

    it "displays number of results found" do
      expect(cases_search_page).to have_search_results_count
      expect(cases_search_page).to have_found_no_results_copy
    end

    it "does not display the download cases link" do
      expect(cases_search_page).to have_no_download_cases_link
    end
  end

  context "when found some results" do
    before do
      login_as create(:user)
      create :report_type
      standard_report_1 = create :report_type, standard_report: true
      create :case
      assign(:query, create(:search_query, search_text: "some search term"))
      assign(:cases, Case::Base.all.page(1).decorate)
      assign(:action_url, "/cases/search")
      assign(:available_reports, [standard_report_1])
      render
      cases_search_page.load(rendered)
    end

    it "shows a search field" do
      expect(cases_search_page).to have_search_query
    end

    it "displays the filters" do
      expect(cases_search_page).to have_case_filters
    end

    it "displays number of results found" do
      expect(cases_search_page).to have_search_results_count
    end

    it "displays the download cases link" do
      expect(cases_search_page).to have_download_cases_link
    end
  end
end
