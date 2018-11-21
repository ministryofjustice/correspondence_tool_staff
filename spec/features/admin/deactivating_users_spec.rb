require 'rails_helper'

feature 'deactivating users' do
  given!(:manager)        { find_or_create :disclosure_bmt_user }
  given!(:responder)      { create :responder, responding_teams: [bu] }
  given!(:user_with_cases){ find_or_create :foi_responder }
  given!(:live_case)      { create :accepted_case }
  given!(:bu)             { find_or_create :foi_responding_team }

  scenario 'manager deactivates a responder with no live cases' do
    login_as manager

    teams_show_page.load(id: bu.id)
    information_officer = teams_show_page.row_for_information_officer(responder.email)
    information_officer.actions.click

    expect(users_edit_page).to be_displayed

    users_edit_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq responder

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(responder.email, responder.password)
    expect(login_page.error_message).to have_content 'Invalid email or password.'
  end

  scenario 'manager deactivates responder with live cases' do
    login_as manager

    teams_show_page.load(id: bu.id)
    information_officer = teams_show_page.row_for_information_officer(user_with_cases.email)

    information_officer.actions.click
    expect(users_show_page).to be_displayed

    users_show_page.deactivate_user_button.click
    users_destroy_page.deactivate_user_button.click
    # expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq user_with_cases

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(user_with_cases.email, user_with_cases.password)
    expect(login_page.error_message).to have_content 'Invalid email or password.'
  end
end
