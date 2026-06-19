require "rails_helper"

feature "when extending a SAR case deadline" do
  include Features::Interactions

  given(:manager)             { find_or_create :disclosure_bmt_user }
  given!(:original_deadline)  { kase.external_deadline }
  given!(:received_date) { kase.received_date }

  context "with a manager" do
    given!(:kase) { freeze_time { create :accepted_sar } }

    scenario "extending a SAR case once by a fixed two months then removing the extension" do
      # Expected date for display: original deadline (1 month) plus a 2 month extension
      expected_extension_date = get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y")

      login_as manager

      # 1. Can extend SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).not_to have_remove_sar_deadline_extension

      # 2. The extension is a fixed 2 months - no period to choose
      extend_sar_deadline_for(kase:, num_calendar_months: 2) do |page|
        expect(page).not_to have_extension_period_1_calendar_month
        expect(page).not_to have_extension_period_2_calendar_months
        expect(page).to have_text("This will extend the deadline by 2 calendar months.")
        expect(page).to have_text("Current deadline: 31 October 2022")
        expect(page).to have_text("New deadline: 29 December 2022")
        expect(page).to have_css("strong", text: "Current deadline:")
        expect(page).to have_css("strong", text: "New deadline:")
        expect(page).to have_text("Add your reasons for extending the deadline")
      end

      case_deadline_text_to_be(expected_extension_date)

      # 3. No longer able to extend, only remove
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.case_status.deadlines.actions).not_to have_extend_sar_deadline
      expect(cases_show_page.case_status.deadlines.actions).to have_remove_sar_deadline_extension

      # 4. Trying to extend again displays an error message
      visit new_case_sar_extension_path(kase)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq("SAR deadline cannot be extended")

      # 5. Removing shows an interstitial page with the current and reverted deadlines
      cases_show_page.load(id: kase.id)
      cases_show_page.case_status.deadlines.actions.remove_sar_deadline_extension.click
      expect(cases_remove_sar_deadline_extension_page).to be_displayed
      expect(page).to have_text("Current deadline: 29 December 2022")
      expect(page).to have_text("New deadline: 31 October 2022")
      expect(page).to have_css("strong", text: "Current deadline:")
      expect(page).to have_css("strong", text: "New deadline:")
      expect(page).to have_text("Add your reasons for removing the deadline extension")

      # 6. Submitting removes the extension and reverts to the initial deadline
      cases_remove_sar_deadline_extension_page.set_reason_for_removing_extension("No longer required")
      cases_remove_sar_deadline_extension_page.submit_button.click
      expect(cases_show_page).to be_displayed
      case_deadline_text_to_be(original_deadline.strftime("%-d %b %Y"))
    end

    scenario "extending a SAR case, pausing then removing extension deadline" do
      login_as manager
      cases_show_page.load(id: kase.id)
      case_deadline_text_to_be("31 Oct 2022")

      # Extend by a fixed 2 months
      extend_sar_deadline_for(kase:, num_calendar_months: 2)

      case_deadline_text_to_be("29 Dec 2022")

      stop_the_clock_date = received_date + 4.days
      restart_the_clock_date = stop_the_clock_date + 4.days

      # Pause the case
      cases_show_page.case_status.deadlines.actions.stop_the_clock.click
      expect(cases_stop_the_clock_page).to be_displayed
      check("CCTV or BWCF requirements", allow_label_click: true)
      cases_stop_the_clock_page.stop_the_clock_reason.set("Pausing to change final deadline")
      cases_stop_the_clock_page.stop_the_clock_date_day.set(stop_the_clock_date.day)
      cases_stop_the_clock_page.stop_the_clock_date_month.set(stop_the_clock_date.month)
      cases_stop_the_clock_page.stop_the_clock_date_year.set(stop_the_clock_date.year)
      cases_stop_the_clock_page.submit_button.click

      # Restart the clock with a new date
      cases_show_page.case_status.deadlines.actions.restart_the_clock.click
      page.find("#case_restart_the_clock_date_dd").set(restart_the_clock_date.day)
      page.find("#case_restart_the_clock_date_mm").set(restart_the_clock_date.month)
      page.find("#case_restart_the_clock_date_yyyy").set(restart_the_clock_date.year)
      click_button "Restart the clock"

      case_deadline_text_to_be("4 Jan 2023")

      # Remove extension should display initial deadline 31 Oct 2022 plus the 4 paused days
      cases_show_page.load(id: kase.id)
      cases_show_page.case_status.deadlines.actions.remove_sar_deadline_extension.click
      expect(cases_remove_sar_deadline_extension_page).to be_displayed
      expect(page).to have_text("Current deadline: 4 January 2023")
      expect(page).to have_text("New deadline: 4 November 2022")
      cases_remove_sar_deadline_extension_page.set_reason_for_removing_extension("Paused for too long")
      cases_remove_sar_deadline_extension_page.submit_button.click
      expect(cases_show_page.notice.text).to eq "Deadline extension removed"
      case_deadline_text_to_be("4 Nov 2022")

      expected_case_history = [
        "Deadline extension removed",
        "Paused for too long",
        " Old final deadline: 4 January 2023 ",
        "New final deadline: 4 November 2022",
      ]
      expect(cases_show_page.case_history.rows.first.details.text).to include(expected_case_history.join)
    end

    scenario "warns on the remove page when reverting will make the case late" do
      freeze_time do
        late_kase = create :accepted_sar, :extended_deadline_sar, received_date: Date.new(2022, 6, 1)
        login_as manager

        cases_show_page.load(id: late_kase.id)
        cases_show_page.case_status.deadlines.actions.remove_sar_deadline_extension.click

        expect(cases_remove_sar_deadline_extension_page).to be_displayed
        expect(page).to have_text("This will make the case late as the new deadline is in the past.")
      end
    end
  end

  context "with an approver" do
    given!(:approver) { find_or_create :disclosure_specialist }
    given!(:kase) do
      freeze_time do
        create :accepted_sar,
               :flagged_accepted,
               approver:
      end
    end

    scenario "can extend a SAR deadline" do
      login_as approver

      cases_show_page.load(id: kase.id)

      # 1. Extend by the fixed 2 months
      extend_sar_deadline_for(kase:, num_calendar_months: 2)

      case_deadline_text_to_be(get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y"))
    end
  end

  context "with a responder" do
    given(:responder) { kase.responder }
    given!(:kase)     { freeze_time { create :accepted_sar } }

    scenario "cannot extend a SAR deadline" do
      login_as responder

      # 1. No button to extend deadline
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.case_status.deadlines.actions).not_to have_extend_sar_deadline

      # 2. Unauthorized to extend deadline
      visit new_case_sar_extension_path(kase)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq("SAR deadline cannot be extended")
    end
  end

  context "with multiple roles" do
    given!(:multi_roles) { find_or_create :disclosure_specialist }
    given!(:kase) do
      freeze_time do
        create :accepted_sar,
               :flagged_accepted,
               approver: multi_roles
      end
    end

    scenario "a user who is approver and responder can extend a SAR deadline" do
      multi_roles.team_roles << TeamsUsersRole.new(team: kase.responding_team, role: "responder")
      multi_roles.reload
      login_as multi_roles

      cases_show_page.load(id: kase.id)

      extend_sar_deadline_for(kase:, num_calendar_months: 2)

      case_deadline_text_to_be(get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y"))
    end

    scenario "a user who is manager, approver and responder can extend a SAR deadline" do
      multi_roles.team_roles << TeamsUsersRole.new(team: kase.responding_team, role: "responder")
      multi_roles.team_roles << TeamsUsersRole.new(team: manager.teams.first, role: "manager")
      multi_roles.reload
      login_as multi_roles

      cases_show_page.load(id: kase.id)

      extend_sar_deadline_for(kase:, num_calendar_months: 2)

      case_deadline_text_to_be(get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y"))
    end
  end
end
