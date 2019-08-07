require 'rails_helper'

feature 'When viewing an offender sar case' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'adding a note' do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to have_content "Add a note to this case"
    cases_show_page.new_message.input.set "Hi this is nice"
    click_on "Add to case history"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Hi this is nice"
  end
end
