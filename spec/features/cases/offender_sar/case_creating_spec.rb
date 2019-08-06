require 'rails_helper'

feature 'Offender SAR Case creation by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', js: true do
    create_offender_sar_case_step
  end
end
