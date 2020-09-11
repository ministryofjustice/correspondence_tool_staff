require 'rails_helper'

feature 'Offender SAR Case creation by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
    CaseClosure::MetadataSeeder.seed!
  end

  after do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'progressing an offender sar case' do
    cases_show_page.load(id: offender_sar_case.id)

    expect(cases_show_page).to have_content "Mark as waiting for data"
    expect(cases_show_page).to have_content "Data to be requested"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
    click_on "Mark as waiting for data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
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
    expect(cases_show_page).to have_content "Send dispatch letter"
    expect(cases_show_page).to have_content "Close case"
    click_on "Close case"
    
    expect(cases_close_page).to be_displayed
    cases_close_page.fill_in_date_responded(offender_sar_case.received_date)
    click_on "Continue"

    expect(cases_closure_outcomes_page).not_to be_displayed

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Closed"
    expect(cases_show_page).to have_content "Send dispatch letter"
    # TODO - pending decision on closure outcomes https://dsdmoj.atlassian.net/browse/CT-2502
    # expect(cases_show_page).to have_content "Was the information held?"
    # expect(cases_show_page).to have_content "Yes"
  end
end
