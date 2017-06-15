require 'rails_helper'

feature 'Case creation by a manager' do

  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }


  background do
    responding_team
    create :team_dacu_disclosure
    create(:category, :foi)
    login_as manager
    cases_page.load
    cases_page.new_case_button.click
  end

  scenario 'creating a case that does not need clearance' do
    expect(cases_new_page).to be_displayed

    cases_new_page.fill_in_case_details

    cases_new_page.choose_flag_for_disclosure_specialists 'no'

    click_button 'Next - Assign case'

    expect(assignments_new_page).to be_displayed

    choose responding_team.name
    click_button 'Assign case'

    expect(cases_show_page).to be_displayed

    expect(cases_show_page.text).to have_content('Case successfully created')

  end

  scenario 'creating a case that needs clearance' do
    expect(cases_new_page).to be_displayed

    cases_new_page.fill_in_case_details

    cases_new_page.choose_flag_for_disclosure_specialists 'yes'

    click_button 'Next - Assign case'

    new_case = Case.last
    expect(new_case.requires_clearance?).to be true
  end

end
