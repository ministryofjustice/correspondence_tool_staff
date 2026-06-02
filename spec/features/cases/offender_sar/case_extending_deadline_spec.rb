require "rails_helper"

feature "when extending an Offender SAR case deadline" do
  include Features::Interactions::OffenderSAR

  given!(:branston_team) { find_or_create :team_branston }
  given!(:offender_sars_manager_responder_team_admin) { find_or_create :responder_and_team_admin_and_manager }

  context "with a manager who is also a responder and team admin" do
    given!(:kase) { freeze_time { create :offender_sar_case } }
    given!(:received_date) { kase.received_date }

    scenario "extending by 1 month, pausing, restarting, extending again, then confirming no further extensions" do
      expected_first_extension_date = get_expected_deadline(2.months.since(received_date)).strftime("%-d %b %Y")

      login_as offender_sars_manager_responder_team_admin

      # 1. Can extend Offender SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).not_to have_remove_sar_deadline_extension

      # 2. Extend by 1 month for the first time
      extend_offender_sar_deadline_for(kase:, reason: "First Offender SAR extension") do |page|
        page.extension_period_1_calendar_month.click
      end

      expected_case_history = [
        "Extended SAR deadline",
        "First Offender SAR extension ",
        "Deadline extended by one calendar month\n",
        "Old final deadline: 7 November 2022 ",
        "New final deadline: 5 December 2022",
      ]
      expect(cases_show_page.case_history.rows.first.details.text).to include(expected_case_history.join)
      expect(cases_show_page.case_status.deadlines.final.text).to eq(expected_first_extension_date)

      # 3. Pause the Offender SAR (stop the clock)
      pause_offender_sar_for(kase:, date: kase.received_date + 10.days)

      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).not_to have_stop_the_clock
      expect(cases_show_page.case_status.deadlines.actions).to have_restart_the_clock
      expect(cases_show_page.case_status.deadlines.final.text).to eq("5 Dec 2022")

      # 4. Restart the Offender SAR
      restart_offender_sar_for(kase:, date: kase.received_date + 15.days)

      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).to have_stop_the_clock
      # Next working day after adding 5 days to the new final deadline of 5th December 2022
      expect(cases_show_page.case_status.deadlines.final.text).to eq("12 Dec 2022")

      # 5. Extend by 1 month again (second time - no extension period selector shown)
      extend_offender_sar_deadline_for(kase:, reason: "Second Offender SAR extension") do |page|
        expect(page).not_to have_extension_period_1_calendar_month
        expect(page).to have_text("The deadline for this case will be extended by a further one calendar month.")
      end

      expected_case_history = [
        "Extended SAR deadline",
        "Second Offender SAR extension ",
        "Deadline extended by one calendar month\n",
        "Old final deadline: 12 December 2022 ",
        "New final deadline: 12 January 2023",
      ]
      expect(cases_show_page.case_history.rows.first.details.text).to include(expected_case_history.join)
      expect(cases_show_page.case_status.deadlines.final.text).to eq("12 Jan 2023")

      # 6. Confirm no further extensions are allowed
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).not_to have_extend_sar_deadline

      # 7. Remove extensions but final deadline should be based on original received date plus paused/stopped days
      cases_show_page.case_status.deadlines.actions.remove_sar_deadline_extension.click
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.notice.text).to eq "Deadline extension removed"
      expect(cases_show_page.case_status.deadlines.final.text).to eq("12 Nov 2022")
    end
  end
end
