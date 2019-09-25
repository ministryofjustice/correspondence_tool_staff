require 'rails_helper'

feature 'Generate an acknowledgement letter by a manager' do
  given(:manager)           { find_or_create :branston_user }
  given(:managing_team)     { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case, :waiting_for_data, name: "Bob").decorate }
  given!(:letter_template)   { find_or_create :letter_template }

  background do
    find_or_create :team_branston
    login_as manager
  end

  scenario 'creating a case that does not need clearance', :js do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    click_on "Send acknowledgement letter"

    expect(cases_new_letter_page).to be_displayed

    cases_new_letter_page.new_letter.first_option.click
    click_on "Continue"

    expect(cases_show_letter_page).to be_displayed
    expect(cases_show_letter_page).to have_content "Thank you for your offender subject access request, Bob"
  end
end
