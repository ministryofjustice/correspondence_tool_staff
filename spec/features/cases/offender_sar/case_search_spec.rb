require "rails_helper"

feature "Searching for cases" do
  given(:responder) { find_or_create :branston_user }
  given(:manager) { find_or_create :disclosure_bmt_user }

  given!(:kase) { create :case_being_drafted, subject: "Common text" }
  given!(:offender_sar_case) { create :offender_sar_case, subject_full_name: "Common text" }
  given!(:offender_sar_case_bill) { create :offender_sar_case, subject_full_name: "Bill", date_of_birth: Date.new(1970, 8, 21), received_date: 3.days.ago }
  given!(:offender_sar_case_bill_1980) { create :offender_sar_case, subject_full_name: "Bill", date_of_birth: Date.new(1980, 8, 21) }
  given!(:offender_sar_case_ted) { create :offender_sar_case, subject_full_name: "Terrence", date_of_birth: Date.new(1970, 8, 21) }

  before do
    kase.update_index
    offender_sar_case.update_index
    offender_sar_case_bill.update_index
    offender_sar_case_bill_1980.update_index
    offender_sar_case_ted.update_index

    login_as searcher
    cases_page.load

    cases_page.primary_navigation.search.click
    expect(cases_search_page).to be_displayed # rubocop:disable RSpec/ExpectInHook
    expect(cases_search_page).not_to have_notices # rubocop:disable RSpec/ExpectInHook
    cases_search_page.search_query.set search_term
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed # rubocop:disable RSpec/ExpectInHook
  end

  context "when searching for case number" do
    let(:searcher) { responder }
    let(:search_term) { offender_sar_case.number }

    scenario "finds offender sar case by case number" do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case.number
    end
  end

  context "when searching for partial name" do
    let(:searcher) { responder }
    let(:search_term) { "Terren" }

    scenario "finds a single case" do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_ted.number
    end
  end

  context "when searching for shared year of birth" do
    let(:searcher) { responder }
    let(:search_term) { "1970" }

    scenario "finds two cases" do
      expect(cases_search_page.search_results_count.text).to eq "2 cases found"
      expect(cases_search_page.case_list.count).to eq 2
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_bill.number
      expect(cases_search_page.case_list.last.number).to have_text offender_sar_case_ted.number
    end
  end

  context "when searching for subject full name" do
    let(:searcher) { responder }
    let(:search_term) { "Bill" }

    scenario "finds two cases with default order: oldest cases first" do
      expect(cases_search_page.search_results_count.text).to eq "2 cases found"
      expect(cases_search_page.case_list.count).to eq 2
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_bill.number
      expect(cases_search_page.case_list.last.number).to have_text offender_sar_case_bill_1980.number
    end

    scenario "finds two cases with newest cases first" do
      expect(cases_search_page.search_results_count.text).to eq "2 cases found"
      expect(cases_search_page.case_list.count).to eq 2
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_bill.number
      expect(cases_search_page.case_list.last.number).to have_text offender_sar_case_bill_1980.number

      click_on "Show newest cases first"
      expect(cases_search_page.case_list.count).to eq 2
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_bill_1980.number
      expect(cases_search_page.case_list.last.number).to have_text offender_sar_case_bill.number
    end
  end

  context "when searching multiple terms narrows the search" do
    let(:searcher) { responder }
    let(:search_term) { "Bill 1970" }

    scenario "finds a single case" do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case_bill.number
    end
  end

  context "when searching for common text as manager" do
    let(:searcher) { manager }
    let(:search_term) { "Common text" }

    scenario "finds FOI case but not offender sar case" do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text kase.number
    end
  end

  context "when searching for common text as branston responder" do
    let(:searcher) { responder }
    let(:search_term) { "Common text" }

    scenario "finds offender_sar_case but not FOI" do
      expect(cases_search_page.search_results_count.text).to eq "1 case found"
      expect(cases_search_page.case_list.count).to eq 1
      expect(cases_search_page.case_list.first.number).to have_text offender_sar_case.number
    end
  end
end
