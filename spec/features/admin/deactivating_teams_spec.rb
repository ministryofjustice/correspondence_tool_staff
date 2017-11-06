require 'rails_helper'

feature 'deactivating users' do
  given!(:manager)         { create :manager }
  given!(:dir)             { create :dacu_directorate }

  scenario 'manager deactivates a team with no active children' do
    login_as manager

    teams_show_page.load(id: dir.id)
    teams_show_page.deactivate_team_link.click

    expect(teams_show_page.flash_notice.text).to eq 'This team has now been deactivated'
  end
end
