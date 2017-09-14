require 'rails_helper'

feature 'deactivating users' do
  given!(:responder)       { create :responder }
  given!(:manager)         { create :manager }
  given!(:bu)              { responder.teams.first }


  scenario 'manager deactivates a responder with no live cases' do
    login_as manager

    teams_show_page.load(id: bu.id)
    information_officer = teams_show_page.information_officers_list.first
    information_officer.actions.click
    expect(users_show_page).to be_displayed

    users_show_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "This account has now been deactivated."
  end
end
