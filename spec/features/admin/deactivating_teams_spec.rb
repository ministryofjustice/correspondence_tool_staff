# require 'rails_helper'
#
# feature 'deactivating users' do
#   given(:manager)         { create :manager }
#   given(:dir)             { create :dacu_directorate }
#   given(:active_dir)      { create :dacu_directorate, name: "directorate"}
#   let!(:business_unit)    { create :business_unit, directorate: active_dir }
#
#
#   scenario 'manager deactivates a team with no active children' do
#     login_as manager
#
#     teams_show_page.load(id: dir.id)
#     teams_show_page.deactivate_team_link.click
#
#     expect(teams_show_page.flash_notice.text).to eq I18n.t('teams.destroyed')
#   end
#
#   scenario 'manager deactivates a team with no active children' do
#     login_as manager
#
#     teams_show_page.load(id: active_dir.id)
#     teams_show_page.deactivate_team_link.click
#
#     expect(teams_show_page.flash_alert.text).to eq I18n.t('teams.error')
#   end
# end
