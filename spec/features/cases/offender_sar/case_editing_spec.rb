require 'rails_helper'

feature 'Offender SAR Case editing by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario 'creating a case that does not need clearance', js: true do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    cases_show_page.offender_sar_subject_details.change_link.click
    expect(cases_edit_offender_sar_subject_details_page).to be_displayed
    cases_edit_offender_sar_subject_details_page.edit_name 'Bob Hope'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content 'Bob Hope'
    expect(cases_show_page).to have_content 'Case edited successfully'

  end
end
