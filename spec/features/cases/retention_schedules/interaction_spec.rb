require 'rails_helper'

feature 'Case retention schedules for GDPR', :js do
  let(:branston_team_admin_user)   { find_or_create :branston_user }
  let(:branston_user)         { create :branston_user, email: 'non.team.admin@test.com' }

  given(:admin_team)          { find_or_create :team_for_admin_users }

  given(:non_branston_user)   { find_or_create :disclosure_bmt_user }
  given(:non_branston_team)   { create :managing_team, managers: [non_branston_user] }

  before do
    tur = TeamsUsersRole.new(
      team_id: admin_team.id,
      user_id: branston_team_admin_user.id,
      role: 'team_admin'
    )

    branston_team_admin_user.team_roles << tur
  end

  ## Dates > 8 years
  # not set
  let!(:not_set_timely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'not_set',
      date: Date.today - 4.months
    )
  }

  # review
  let!(:reviewable_timely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'review',
      date: Date.today
    )
  }

  let!(:reviewable_untimely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'review',
      date: Date.today + 5.months
    )
  }

  # retain
  let!(:retain_timely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'retain',
      date: Date.today - 4.months
    )
  }

  let!(:retain_untimely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'retain',
      date: Date.today + 5.months
    )
  }

  # erasable
  let!(:erasable_timely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'to_be_anonymised',
      date: Date.today - 4.months
    )
  }

  let!(:erasable_timely_kase_two) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'to_be_anonymised',
      date: Date.today - 3.months
    )
  }

  let!(:erasable_untimely_kase) {
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: 'to_be_anonymised',
      date: Date.today + 5.months
    )
  }

  let!(:erasable_pending_kases) {
    2.times.map {
      case_with_retention_schedule(
        case_type: :offender_sar_case,
        case_state: :closed,
        rs_state: 'to_be_anonymised',
        date: Date.today + 2
      )
    }
  }

  scenario 'non admin branston users cannot manage RRD schedules of cases' do
    login_as branston_user

    cases_page.load

    expect(page).to_not have_content 'RRD Pending'
  end

  scenario 'branston team admin users can managers RRD schedules of cases' do
    login_as branston_team_admin_user

    cases_page.load

    expect(page).to have_content 'RRD Pending'

    cases_page.homepage_navigation.case_retention.click
    #
    # simple check to see Linked Case column has data
    expect(page).to have_content 'No'

    expect(page).to have_content 'Pending removal'
    expect(page).to have_content 'Ready for removal'

    expect(page).to have_content '2 cases found'

    expect(page).to have_content erasable_timely_kase.number
    expect(page).to have_content erasable_timely_kase_two.number

    expect(page).to_not have_content erasable_untimely_kase.number

    click_on 'Pending removal'

    expect(page).to have_content '5 cases found'
    expect(page).to_not have_content 'Destroy cases'


    expect(page).to have_content not_set_timely_kase.number
    expect(page).to have_content reviewable_timely_kase.number
    expect(page).to have_content retain_timely_kase.number

    erasable_pending_kases.each do |kase|
      expect(page).to have_content kase.number
    end

    expect(page).to_not have_content reviewable_untimely_kase.number
    expect(page).to_not have_content retain_untimely_kase.number

    Capybara.find(:css, "#retention-checkbox-#{not_set_timely_kase.id}", visible: false).set(true)
    Capybara.find(:css, "#retention-checkbox-#{retain_timely_kase.id}", visible: false).set(true)


    click_on "Mark for destruction"

    expect(page).to_not have_content not_set_timely_kase.number
    expect(page).to_not have_content retain_timely_kase.number

    expect(page).to have_content("2 cases have been marked for destruction")

    click_on 'Ready for removal'

    expect(page).to have_content not_set_timely_kase.number
    expect(page).to have_content retain_timely_kase.number
    erasable_pending_kases.each do |kase|
      expect(page).not_to have_content kase.number
    end

    click_on 'Show newest destruction date first'

    page_order_correct?(
      retain_timely_kase.number.to_s,
      not_set_timely_kase.number.to_s
    )

    expect(page).to have_content 'Show oldest destruction date first'

    click_on 'Show oldest destruction date first'
    page_order_correct?(
      not_set_timely_kase.number.to_s,
      retain_timely_kase.number.to_s
    )

    Capybara.find(:css, "#retention-checkbox-#{not_set_timely_kase.id}", visible: false).set(true)

    accept_alert do
      click_on "Destroy cases"
    end

    expect(page).to_not have_content not_set_timely_kase.number

    click_on 'Pending removal'

    expect(page).to_not have_content not_set_timely_kase.number

    not_set_timely_kase.reload

    expect(not_set_timely_kase.retention_schedule.aasm.current_state).to eq(:anonymised)
  end

  scenario 'non branston users cannot see the GDPR tab' do
    login_as non_branston_user

    cases_page.load

    expect(page).to_not have_content 'Case Retention'
  end

  def page_order_correct?(before_text, after_text)
    before = page.text.index(before_text)
    after = page.text.index(after_text)
    before < after
  end

  def case_with_retention_schedule(case_type:, case_state:, rs_state:, date:)
      kase = create(
        case_type,
        current_state: case_state,
        date_responded: Date.today,
        retention_schedule:
          RetentionSchedule.new(
           state: rs_state,
           planned_destruction_date: date
        )
      )

    kase.save
    kase
  end
end
