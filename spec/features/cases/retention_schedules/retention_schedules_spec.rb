require 'rails_helper'

feature 'Case retention schedules for GDPR', :js do
  given(:branston_user)         { find_or_create :branston_user }
  given(:branston_team)   { create :managing_team, managers: [branston_user] }
  given(:offender_sar_case) { create :offender_sar_case, :third_party, received_date: 2.weeks.ago.to_date }

  given(:non_branston_user)         { find_or_create :disclosure_bmt_user }
  given(:non_branston_team)   { create :managing_team, managers: [non_branston_user] }


  ##
  # - Create 3 cases in each retention status group
  # - User can load pages and see the correct cases on each tab
  # - update factories to make this easier
  
  ### Dates > 8 years
  ## not set
  #let(:kase_one) { create(:offender_sar_case) }

  ## review
  #let(:kase_two) { create(:offender_sar_case) }

  ## erasable
  #let(:kase_three) { create(:offender_sar_case) }

  ##retain
  #let(:kase_four) { create(:offender_sar_case) }

  ### dates < 8 years
  ## One not set one erasable
  #let(:kase_five) { create(:offender_sar_case) }
  #let(:kase_six) { create(:offender_sar_case) }

  scenario 'branston users can see the GDPR tab' do
    login_as branston_user
    
    cases_page.load

    expect(page).to have_content 'Case Retention'

    cases_page.homepage_navigation.case_retention.click

    expect(page).to have_content 'Pending removal'
    expect(page).to have_content 'Ready for removal'
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
