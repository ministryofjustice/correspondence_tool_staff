require 'rails_helper'

feature 'deactivating directorates' do
  given(:dir)             { create :dacu_directorate, name: "dir1" }
  given(:active_dir)      { create :dacu_directorate, name: "directorate"}
  let!(:business_unit)    { create :business_unit, directorate: active_dir }
  given(:manager)         { create :manager }

  scenario 'manager deactivates a directorate with no active children' do
    login_as manager

    teams_show_page.load(id: dir.id)
    teams_show_page.deactivate_team_link.click

    expect(teams_show_page.flash_notice.text).to eq(
    "#{dir.name} Directorate has now been deactivated")
  end
end

feature 'deactivating business units' do
  given(:dir)             { find_or_create :directorate, name: 'dir' }
  given!(:bu)             { create :business_unit, directorate: dir }
  given(:manager)         { create :manager }

  scenario 'manager deactivates a business unit with no active children' do
    login_as manager

    teams_show_page.load(id: dir.id)
    expect(teams_show_page.row_for_business_unit(bu.name).name.text).to have_text(bu.name)

    teams_show_page.load(id: bu.id)
    teams_show_page.deactivate_team_link.click
    expect(teams_show_page.flash_notice.text).to eq(
    "#{bu.name} Business unit has now been deactivated")

    expect(teams_show_page).to be_displayed(id: dir.id)
    expect(teams_show_page.row_for_business_unit(bu.name)).to equal nil
  end
end
