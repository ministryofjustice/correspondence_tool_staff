require 'rails_helper'

feature 'OSAR Case creation by a manager' do

  given(:responder)       { find_or_create(:foi_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', js: true do
    create_osar_case_step

    # TODO: make these subsequent tests work
    # responding_team = responder.responding_teams.first
    # assign_case_step business_unit: responding_team

    # # Clearance level should display deputy director
    # expect(cases_show_page.clearance_levels.basic_details.deputy_director.text)
    #   .to include responding_team.team_lead
  end
end
