require "rails_helper"

feature "when extending an Offender SAR case deadline" do
  include Features::Interactions::OffenderSAR

  given!(:branston_team) { find_or_create :team_branston }
  given!(:offender_sars_manager_responder_team_admin) { find_or_create :responder_and_team_admin_and_manager }

  context "with a manager who is also a responder and team admin" do
    given!(:kase) { freeze_time { create :offender_sar_case } }
    given!(:received_date) { kase.received_date }

    scenario "extending once by a fixed two months, pausing, restarting, then confirming no further extensions" do
      expected_extension_date = get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y")

      login_as offender_sars_manager_responder_team_admin

      # 1. Can extend Offender SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).not_to have_remove_sar_deadline_extension

      # 2. Extend by the fixed 2 months - no period to choose
      extend_offender_sar_deadline_for(kase:, reason: "Offender SAR extension") do |page|
        expect(page).not_to have_extension_period_1_calendar_month
        expect(page).not_to have_extension_period_2_calendar_months
        expect(page).to have_text("This will extend the deadline by 2 calendar months.")
        expect(page).to have_text("Current deadline: 7 November 2022")
        expect(page).to have_text("New deadline: 5 January 2023")
      end

      expected_case_history = [
        "Extended SAR deadline",
        "Offender SAR extension ",
        "Deadline extended by two calendar months\n",
        "Old final deadline: 7 November 2022 ",
        "New final deadline: 5 January 2023",
      ]
      expect(cases_show_page.case_history.rows.first.details.text).to include(expected_case_history.join)
      expect(cases_show_page.case_status.deadlines.final.text).to eq(expected_extension_date)

      # 3. Pause the Offender SAR (stop the clock)
      pause_offender_sar_for(kase:, date: kase.received_date + 10.days)

      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).not_to have_stop_the_clock
      expect(cases_show_page.case_status.deadlines.actions).to have_restart_the_clock
      expect(cases_show_page.case_status.deadlines.final.text).to eq("5 Jan 2023")

      # 4. Restart the Offender SAR - still no further extension allowed (single fixed extension)
      restart_offender_sar_for(kase:, date: kase.received_date + 15.days)

      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).not_to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).to have_stop_the_clock
      # 5 calendar days added to the new final deadline of 5th January 2023
      expect(cases_show_page.case_status.deadlines.final.text).to eq("10 Jan 2023")

      # 5. Confirm extending again is rejected
      visit new_case_sar_extension_path(kase)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq("SAR deadline cannot be extended")

      # 6. Remove extension but final deadline should be based on original received date plus paused/stopped days
      cases_show_page.load(id: kase.id)
      cases_show_page.case_status.deadlines.actions.remove_sar_deadline_extension.click
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice.text).to eq "Deadline extension removed"

      # 12th Nov is a Saturday, so next working day is 14th Nov
      expect(cases_show_page.case_status.deadlines.final.text).to eq("14 Nov 2022")
    end
  end
end
