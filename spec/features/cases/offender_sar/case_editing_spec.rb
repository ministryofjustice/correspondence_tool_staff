require 'rails_helper'

feature 'Offender SAR Case editing by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case, received_date: 2.weeks.ago.to_date }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario 'editing an offender SAR case', js: true do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    cases_show_page.offender_sar_subject_details.change_link.click
    expect(cases_edit_offender_sar_subject_details_page).to be_displayed
    cases_edit_offender_sar_subject_details_page.edit_name 'Bob Hope'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content 'Bob Hope'
    expect(cases_show_page).to have_content 'Case edited successfully'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requester_details.change_link.click
    expect(cases_edit_offender_sar_requester_details_page).to be_displayed
    cases_edit_offender_sar_requester_details_page.edit_email 'bob_hope@example.com'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content 'bob_hope@example.com'
    expect(cases_show_page).to have_content 'Case edited successfully'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_date_received.change_link.click
    expect(cases_edit_offender_sar_date_received_page).to be_displayed
    cases_edit_offender_sar_date_received_page.edit_received_date 1.week.ago.to_date
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content I18n.l(1.week.ago.to_date, format: :default)
    expect(cases_show_page).to have_content 'Case edited successfully'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requested_info.change_link.click
    expect(cases_edit_offender_sar_requested_info_page).to be_displayed
    cases_edit_offender_sar_requested_info_page.edit_message "In a hole in the ground there lived a Hobbit."
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content "In a hole in the ground there lived a Hobbit."
    expect(cases_show_page).to have_content 'Case edited successfully'
    expect(cases_show_page).to have_content 'Case details edited'
  end
end
