require 'rails_helper'

feature 'Case retention schedules for GDPR', :js do
  given(:branston_user)         { find_or_create :branston_user }
  given(:branston_team)   { create :managing_team, managers: [branston_user] }
  given(:offender_sar_case) { create :offender_sar_case, :third_party, received_date: 2.weeks.ago.to_date }

  given(:non_branston_user)         { find_or_create :disclosure_bmt_user }
  given(:non_branston_team)   { create :managing_team, managers: [non_branston_user] }

  scenario 'branston users can see the GDPR tab' do
    login_as branston_user
    
    cases_page.load

    expect(page).to have_content 'Case Retention'
  end

  scenario 'non branston users cannot see the GDPR tab' do
    login_as non_branston_user

    cases_page.load

    expect(page).to_not have_content 'Case Retention'
  end

  scenario 'if feature is on then retention tab does not appear' do
    disable_feature(:branston_retention_scheduling)
    login_as branston_user

    cases_page.load
    expect(page).to_not have_content 'Case Retention'
  end
end
