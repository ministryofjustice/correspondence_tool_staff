require "rails_helper"

feature "Searching for cases" do
  given(:approver)        { find_or_create :disclosure_specialist }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:responder)       { kase.responder }
  given!(:kase_earlier)   { create :case_being_drafted, name: "testing", received_date: 1.month.ago }
  given!(:kase)           { create :case_being_drafted, name: "testing" }

  scenario "searching by case number" do
    login_as manager

    cases_page.load
    cases_page.primary_navigation.search.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices

    kase.update_index
    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end

  scenario "searching as a responder" do
    login_as responder

    kase.update_index
    cases_page.load
    cases_page.primary_navigation.search.click
    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end

  scenario "searching as an approver" do
    login_as approver

    kase.update_index
    cases_page.load
    cases_page.primary_navigation.search.click
    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end

  scenario "searching by case name with choice of ordering the search result" do
    login_as manager

    cases_page.load
    kase.update_index
    kase_earlier.update_index
    cases_search_page.search_query.set "testing"
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices
    expect(cases_search_page.search_results_count.text).to eq "2 cases found"
    expect(cases_search_page.case_list.count).to eq 2
    expect(cases_search_page.case_list.first.number).to have_text kase_earlier.number
    expect(cases_search_page.case_list.second.number).to have_text kase.number

    click_on "Show newest cases first"

    expect(cases_search_page.search_results_count.text).to eq "2 cases found"
    expect(cases_search_page.case_list.count).to eq 2
    expect(cases_search_page.case_list.first.number).to have_text kase.number
    expect(cases_search_page.case_list.second.number).to have_text kase_earlier.number
  end
end
