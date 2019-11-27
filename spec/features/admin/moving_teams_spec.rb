require 'rails_helper'

feature 'moving business units' do
  given(:origin_directorate) { find_or_create :directorate, name: 'Origin Directorate' }
  given!(:bu) { create :business_unit, directorate: origin_directorate }
  given(:manager) { create :manager }

  scenario 'manager moves a business unit', :js do
    login_as manager

    teams_show_page.load(id: origin_directorate.id)
    expect(teams_show_page.row_for_business_unit(bu.name).name.text).to have_text(bu.name)

    teams_show_page.load(id: bu.id)
    teams_show_page.move_team_link.click
    expect(teams_move_page).to be_displayed(id: bu.id)

    teams_move_page.business_groups.links.first.click
    expect(teams_move_page).to have_content "This is where the team is currently located"
    teams_move_page.business_groups.links.last.click
    accept_confirm do
      teams_move_page.directorates_list.directorates.first.move_to_directorate_link.click
    end

    expect(teams_show_page.flash_notice.text).to eq(
    "#{BusinessUnit.last.name} has been moved to Responder Directorate")
  end
end
