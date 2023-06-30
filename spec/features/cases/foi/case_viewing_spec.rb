require "rails_helper"

feature "Viewing for cases" do
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given!(:kase_earlier)   { create :case_being_drafted, name: "testing", received_date: 20.days.ago }
  given!(:kase)           { create :case_being_drafted, name: "testing" }
  given(:responder)       { kase.responder }

  scenario "View open-cases tab - choice of ordering the result" do
    login_as manager

    cases_page.load
    cases_page.primary_navigation.all_open_cases.click
    expect(cases_page.case_list.count).to eq 2
    expect(cases_page.case_list.first.number).to have_text kase_earlier.number
    expect(cases_page.case_list.second.number).to have_text kase.number

    click_on "Show newest cases first"

    expect(cases_page.case_list.count).to eq 2
    expect(cases_page.case_list.first.number).to have_text kase.number
    expect(cases_page.case_list.second.number).to have_text kase_earlier.number
  end

  scenario "View my-open-cases tab - choice of ordering the result" do
    login_as responder

    cases_page.load
    cases_page.primary_navigation.my_open_in_time.click
    expect(cases_page.case_list.count).to eq 2
    expect(cases_page.case_list.first.number).to have_text kase_earlier.number
    expect(cases_page.case_list.second.number).to have_text kase.number

    click_on "Show newest cases first"

    expect(cases_page.case_list.count).to eq 2
    expect(cases_page.case_list.first.number).to have_text kase.number
    expect(cases_page.case_list.second.number).to have_text kase_earlier.number
  end
end
