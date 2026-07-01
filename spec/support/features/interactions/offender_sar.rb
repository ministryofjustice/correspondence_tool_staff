module Features
  module Interactions
    module OffenderSAR
      def extend_offender_sar_deadline_for(kase:, reason: "Testing out Offender SAR deadline extension")
        cases_show_page.load(id: kase.id)
        cases_show_page.case_status.deadlines.actions.extend_sar_deadline.click

        expect(cases_extend_sar_deadline_page).to be_displayed

        yield(cases_extend_sar_deadline_page) if block_given?

        cases_extend_sar_deadline_page.set_reason_for_extending(reason)
        cases_extend_sar_deadline_page.submit_button.click

        expect(cases_show_page).to be_displayed
        expect(cases_show_page.notice.text).to eq "The deadline has been extended by 2 months."
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
      end
    end
  end
end
