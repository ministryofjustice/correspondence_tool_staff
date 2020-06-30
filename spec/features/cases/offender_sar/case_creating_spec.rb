require 'rails_helper'

feature 'Offender SAR Case creation by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', js: true do
    expect(cases_page).to have_new_case_button
    cases_page.new_case_button.click
    expect(cases_new_page).to be_displayed

    cases_new_page.create_link_for_correspondence('OFFENDER').click
    expect(cases_new_offender_sar_subject_details_page).to be_displayed

    cases_new_offender_sar_subject_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_requester_details_page).to be_displayed

    cases_new_offender_sar_requester_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_recipient_details_page).to be_displayed

    cases_new_offender_sar_recipient_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_requested_info_page).to be_displayed

    cases_new_offender_sar_requested_info_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_request_details_page).to be_displayed

    cases_new_offender_sar_request_details_page.fill_in_case_details
    click_on "Continue"
    expect(cases_new_offender_sar_date_received_page).to be_displayed

    cases_new_offender_sar_date_received_page.fill_in_case_details
    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case created successfully"
    expect(cases_show_page.page_heading).to have_content "Sabrina Adams"
    click_on "Cases"

    expect(open_cases_page).to be_displayed
    expect(cases_page).to have_content "Branston Registry"
    expect(open_cases_page).to have_content "Sabrina Adams"

  end
end
