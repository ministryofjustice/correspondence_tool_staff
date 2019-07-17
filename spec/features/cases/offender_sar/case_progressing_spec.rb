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

  scenario 'creating a case that does not need clearance', js: true do
    # create_offender_sar_case_step
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to have_content "Mark as waiting for data"
    click_on "Mark as waiting for data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
  end
end
