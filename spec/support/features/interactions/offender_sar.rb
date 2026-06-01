module Features
  module Interactions
    module OffenderSAR
      def extend_offender_sar_deadline_for(kase:, num_calendar_months:, reason: "Testing out Offender SAR deadline extension")
        cases_show_page.load(id: kase.id)
        cases_show_page.case_status.deadlines.actions.extend_sar_deadline.click

        expect(cases_extend_sar_deadline_page).to be_displayed

        yield(cases_extend_sar_deadline_page) if block_given?

        cases_extend_sar_deadline_page.set_reason_for_extending(reason)
        cases_extend_sar_deadline_page.submit_button.click

        old_final_deadline = kase.external_deadline
        kase.reload

        expected_case_history = [
          "Extended SAR deadline",
          reason.to_s,
          " Deadline extended by #{num_calendar_months == 1 ? 'one' : 'two'} calendar #{'month'.pluralize(num_calendar_months)}\n",
          "Old final deadline:#{I18n.localize(old_final_deadline, format: :long)} ",
          "New final deadline:#{I18n.localize(kase.external_deadline, format: :long)}",
        ]

        expect(cases_show_page).to be_displayed
        expect(cases_show_page.notice.text).to eq "Case extended for Offender SAR"
        expect(cases_show_page.case_history.rows.first.details.text).to include(expected_case_history.join)
      end

      def pause_offender_sar_for(kase:, reason: "Pausing to gather more information", date: Time.zone.today)
        cases_show_page.load(id: kase.id)
        cases_show_page.case_status.deadlines.actions.stop_the_clock.click

        expect(cases_stop_the_clock_page).to be_displayed

        check("CCTV or BWCF requirements", allow_label_click: true)
        cases_stop_the_clock_page.stop_the_clock_reason.set(reason)
        cases_stop_the_clock_page.stop_the_clock_date_day.set(date.day)
        cases_stop_the_clock_page.stop_the_clock_date_month.set(date.month)
        cases_stop_the_clock_page.stop_the_clock_date_year.set(date.year)
        cases_stop_the_clock_page.submit_button.click

        expect(cases_show_page).to be_displayed
        expect(cases_show_page.notice.text).to eq "You have stopped the clock on this case."

        kase.reload
      end

      def restart_offender_sar_for(kase:, date: Time.zone.today)
        cases_show_page.load(id: kase.id)
        cases_show_page.case_status.deadlines.actions.restart_the_clock.click

        page.find("#case_restart_the_clock_date_dd").set(date.day)
        page.find("#case_restart_the_clock_date_mm").set(date.month)
        page.find("#case_restart_the_clock_date_yyyy").set(date.year)
        click_button "Restart the clock"

        expect(cases_show_page).to be_displayed
        expect(cases_show_page.notice.text).to eq "You have restarted the clock on this case. The deadlines have been updated."

        kase.reload
      end
    end
  end
end
