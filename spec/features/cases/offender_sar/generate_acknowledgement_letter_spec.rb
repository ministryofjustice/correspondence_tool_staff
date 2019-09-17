require 'rails_helper'

feature 'Generate an acknowledgement letter by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case, :waiting_for_data).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', :js do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    click_on "Send acknowledgement letter"

    expect(cases_new_letter_page).to be_displayed
    sleep 10
  end
end
