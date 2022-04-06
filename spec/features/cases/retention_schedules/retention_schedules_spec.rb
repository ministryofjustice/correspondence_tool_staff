require 'rails_helper'

feature 'Case retention schedules for GDPR', :js do
  given(:branston_user)         { find_or_create :branston_user }
  given(:branston_team)   { create :managing_team, managers: [branston_user] }
  given(:offender_sar_case) { create :offender_sar_case, :third_party, received_date: 2.weeks.ago.today }

  given(:non_branston_user)         { find_or_create :disclosure_bmt_user }
  given(:non_branston_team)   { create :managing_team, managers: [non_branston_user] }


  ## Dates > 8 years
  # not set
  let!(:kase_one) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'not_set',
      date: Date.today - 8.years
    ) 
  }

  # review
  let!(:kase_two) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'review',
      date: Date.today - 8.years
    ) 
  }

  # erasable
  let!(:kase_three) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - 8.years
    ) 
  }

  let!(:kase_four) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - 8.years
    ) 
  }

  # retain
  let!(:kase_five) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'retain',
      date: Date.today - 8.years
    ) 
  }

  ## dates < 8 years
  # One not set one erasable
  let!(:kase_six) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'not_set',
      date: Date.today - 7.years
    ) 
  }

  let!(:kase_seven) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      status: 'erasable',
      date: Date.today - 7.years
    ) 
  }

  scenario 'branston users can see the GDPR tab' do
    login_as branston_user
    
    cases_page.load

    expect(page).to have_content 'Case Retention'

    cases_page.homepage_navigation.case_retention.click

    expect(page).to have_content 'Pending removal'
    expect(page).to have_content 'Ready for removal'


    expect(page).to have_content kase_three.number
    expect(page).to have_content kase_four.number

    # Turn these lets into an array
    # check numbers that shouldn't be there
    # implement date restrictions
    # click other tab
    # check cases should and shouldn't be there
    #
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
