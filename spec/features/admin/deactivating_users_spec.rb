require 'rails_helper'

feature 'deactivating users' do
  given!(:manager)         { create :manager }
  given!(:responder)       { create :responder }
  given!(:bu)              { responder.teams.first }

  scenario 'manager deactivates a responder with no live cases' do
    login_as manager

    teams_show_page.load(id: bu.id)
    information_officer = teams_show_page.information_officers_list.last
    information_officer.actions.click
    expect(users_show_page).to be_displayed

    users_show_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq responder

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(responder.email, responder.password)
    expect(login_page.error_message).to have_content 'Invalid email or password.'
  end
end
