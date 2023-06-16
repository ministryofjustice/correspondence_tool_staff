require "rails_helper"

feature "Case retention schedules for GDPR", :js do
  given(:branston_team_admin_user) { find_or_create :branston_user }
  given(:admin_team) { find_or_create :team_for_admin_users }

  before do
    tur = TeamsUsersRole.new(
      team_id: admin_team.id,
      user_id: branston_team_admin_user.id,
      role: "team_admin",
    )

    branston_team_admin_user.team_roles << tur
  end

  # erasable
  let!(:erasable_timely_kase) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: "to_be_anonymised",
      date: Date.today - 4.months,
    )
  end

  let!(:erasable_timely_kase_two) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: "to_be_anonymised",
      date: Date.today,
    )
  end

  let!(:erasable_untimely_kase) do
    case_with_retention_schedule(
      case_type: :offender_sar_case,
      case_state: :closed,
      rs_state: "to_be_anonymised",
      date: Date.today + 5.months,
    )
  end

  scenario "branston team admin users can see the GDPR tab with correct cases" do
    login_as branston_team_admin_user

    cases_page.load

    expect(page).to have_content "RRD Pending"

    cases_page.homepage_navigation.case_retention.click

    click_on "Ready for removal"

    expect(page).to have_content erasable_timely_kase.number.to_s
    expect(page).to have_content erasable_timely_kase_two.number.to_s

    Capybara.find(:css, "#retention-checkbox-#{erasable_timely_kase.id}", visible: false).set(true)
    Capybara.find(:css, "#retention-checkbox-#{erasable_timely_kase_two.id}", visible: false).set(true)

    accept_alert do
      click_on "Destroy cases"
    end

    expect(page).to have_content "2 cases have been destroyed"

    expect(page).not_to have_content erasable_timely_kase.number
    expect(page).not_to have_content erasable_timely_kase_two.number

    expect_case_to_be_anonymised(kase: erasable_timely_kase)
    expect_case_to_be_anonymised(kase: erasable_timely_kase_two)

    erasable_timely_kase.reload
    erasable_timely_kase_two.reload

    expect(erasable_timely_kase.retention_schedule.aasm.current_state).to eq(:anonymised)
    expect(erasable_timely_kase_two.retention_schedule.aasm.current_state).to eq(:anonymised)
  end

  def expect_case_to_be_anonymised(kase:)
    cases_show_page.load(id: kase.id)
    expect(page).to have_content kase.number.to_s
    expect(page).to have_content "XXXX XXXX"
    expect(page).to have_content "Information has been anonymised"
    expect(page).to have_content "Anon location"

    expect(page).not_to have_content "Start complaint"

    show_page = cases_show_page.case_details

    expect(show_page.retention_details)
      .not_to have_content("Change")
    expect(show_page.retention_details.retention_schedule_state)
      .to have_content("Retention status Anonymised")
    expect(show_page.retention_details.anonymised_at)
      .to have_content("Anonymised on #{I18n.l(Date.today)}")
  end

  def case_with_retention_schedule(case_type:, case_state:, rs_state:, date:)
    kase = create(
      case_type,
      current_state: case_state,
      date_responded: Date.today,
      retention_schedule:
        RetentionSchedule.new(
          state: rs_state,
          planned_destruction_date: date,
        ),
    )

    kase.save!
    kase
  end
end
