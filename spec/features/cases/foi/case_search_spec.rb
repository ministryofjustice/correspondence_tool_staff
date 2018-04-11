require "rails_helper"

feature 'Searching for cases' do
  given(:approver)  { create :approver }
  given(:manager)   { create :manager }
  given(:responder) { create :responder }
  given!(:kase)     { create :case_being_drafted, responder: responder }

  scenario 'searching by case number' do
    login_as manager

    cases_page.load
    cases_page.primary_navigation.search.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices

    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page).not_to have_notices
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end

  scenario 'searching as a responder' do
    login_as responder

    cases_page.load
    cases_page.primary_navigation.search.click
    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end

  scenario 'searching as an approver' do
    login_as approver

    cases_page.load
    cases_page.primary_navigation.search.click
    cases_search_page.search_query.set kase.number
    cases_search_page.search_button.click
    expect(cases_search_page).to be_displayed
    expect(cases_search_page.case_list.count).to eq 1
    expect(cases_search_page.search_results_count.text).to eq "1 case found"
    expect(cases_search_page.case_list.first.number).to have_text kase.number
  end
end
