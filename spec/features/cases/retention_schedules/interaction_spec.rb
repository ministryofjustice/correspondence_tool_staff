require 'rails_helper'

feature 'Case retention schedules for GDPR', :js do
  given(:branston_user)         { find_or_create :branston_user }
  given(:branston_team)   { create :managing_team, managers: [branston_user] }

  given(:non_branston_user)         { find_or_create :disclosure_bmt_user }
  given(:non_branston_team)   { create :managing_team, managers: [non_branston_user] }


  ## Dates > 8 years
  # not set
  let!(:not_set_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'not_set',
      date: Date.today - 4.months
    ) 
  }

  # review
  let!(:reviewable_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'review',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let!(:reviewable_untimely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'review',
      date: Date.today - (5.months)
    ) 
  }
  
  # retain
  let!(:retain_timely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'retain',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let!(:retain_untimely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'retain',
      date: Date.today - (5.months)
    ) 
  }

  # erasable
  let!(:erasable_timely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - 4.months
    ) 
  }

  let!(:erasable_timely_kase_two) {
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - (4.months - 7.days)
    ) 
  }

  let!(:erasable_untimely_kase) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - (5.months)
    ) 
  }

  scenario 'branston users can see the GDPR tab with correct cases' do
    login_as branston_user
    
    cases_page.load

    expect(page).to have_content 'Case Retention'

    cases_page.homepage_navigation.case_retention.click
    
    expect(page).to have_content 'Pending removal'
    expect(page).to have_content 'Ready for removal'

    expect(page).to have_content '2 cases found'

    expect(page).to have_content erasable_timely_kase.number
    expect(page).to have_content erasable_timely_kase_two.number

    expect(page).to_not have_content erasable_untimely_kase.number

    click_on 'Pending removal'

    expect(page).to have_content '3 cases found'
    expect(page).to_not have_content 'Destroy cases'

    expect(page).to have_content not_set_timely_kase.number
    expect(page).to have_content reviewable_timely_kase.number
    expect(page).to have_content retain_timely_kase.number

    expect(page).to_not have_content reviewable_untimely_kase.number
    expect(page).to_not have_content retain_untimely_kase.number

    Capybara.find(:css, "#retention-checkbox-#{not_set_timely_kase.id}", visible: false).set(true)
    Capybara.find(:css, "#retention-checkbox-#{retain_timely_kase.id}", visible: false).set(true)

    click_on "Mark for destruction"

    expect(page).to_not have_content not_set_timely_kase.number
    expect(page).to_not have_content retain_timely_kase.number

    expect(page).to have_content("2 cases retention statuses updated to erasable")
    
    click_on 'Ready for removal'

    expect(page).to have_content not_set_timely_kase.number
    expect(page).to have_content retain_timely_kase.number

    click_on 'Show newest cases first'
    expect(page).to have_content 'Show oldest cases first'
    click_on 'Show oldest cases first'

    Capybara.find(:css, "#retention-checkbox-#{not_set_timely_kase.id}", visible: false).set(true)

    click_on "Destroy cases"

    expect(page).to_not have_content not_set_timely_kase.number

    click_on 'Pending removal'

    expect(page).to_not have_content not_set_timely_kase.number

    not_set_timely_kase.reload

    expect(not_set_timely_kase.retention_schedule.status).to eq('erased')
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

  def case_with_retention_schedule(case_type:, status:, date:)
    kase = create(
      case_type, 
      retention_schedule: 
        RetentionSchedule.new( 
         status: status, 
         planned_erasure_date: date 
      ) 
    )
    kase.save
    kase
  end
end
