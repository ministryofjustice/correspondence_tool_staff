require 'rails_helper'

feature 'Offender SAR Case creation by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance' do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to have_content "Mark as waiting for data"
    expect(cases_show_page).to have_content "Data to be requested"
    click_on "Mark as waiting for data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    click_on "Mark as ready for vetting"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as vetting in progress"
    click_on "Mark as vetting in progress"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to copy"
    click_on "Mark as ready to copy"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to dispatch"
    click_on "Mark as ready to dispatch"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Close case"
    click_on "Close case"
  end
end
