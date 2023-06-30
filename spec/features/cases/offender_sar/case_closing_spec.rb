require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

feature "Closing a case" do
  given(:responder) { find_or_create :branston_user }
  given(:responder_team) { responder.responding_teams.first }

  background do
    # find_or_create :team_branston
    login_as responder
  end

  describe "Reporting timiliness" do
    Timecop.freeze(Time.zone.local(2017, 11, 23, 13, 13, 56)) do
      context "when responded-to in time" do
        given!(:fully_granted_case) do
          create :offender_sar_case,
                 :ready_to_dispatch,
                 received_date: 5.days.ago
        end

        scenario "Offender sar team has responded and a responder closes the case", js: true do
          open_cases_page.load
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.days.ago)
          cases_close_page.click_on "Continue"

          expect(cases_closure_outcomes_page).not_to be_displayed

          show_page = cases_show_page.case_details

          expect(show_page.response_details.date_responded.data.text)
          .to eq 0.days.ago.strftime(Settings.default_date_format)
          expect(show_page.response_details.timeliness.data.text)
          .to eq "Answered in time"
          expect(show_page.response_details.time_taken.data.text)
          .to eq "5 calendar days"
        end
      end

      context "when responded-to late" do
        given!(:fully_granted_case) do
          create :offender_sar_case,
                 :ready_to_dispatch,
                 received_date: 60.days.ago
        end

        scenario "the case is responded-to late", js: true do
          open_cases_page.load(timeliness: "late")
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.days.ago)
          cases_close_page.click_on "Continue"

          expect(cases_closure_outcomes_page).not_to be_displayed

          show_page = cases_show_page.case_details

          expect(show_page.response_details.timeliness.data.text)
            .to eq "Answered late"
          expect(show_page.response_details.time_taken.data.text)
            .to eq "60 calendar days"
        end
      end
    end
  end

  describe "GDPR retention schedules" do
    given!(:fully_granted_case) do
      create :offender_sar_case,
             :ready_to_dispatch,
             received_date: 5.days.ago
    end

    scenario "adds retention schedule details to the page", js: true do
      open_cases_page.load
      close_case(fully_granted_case)

      cases_close_page.fill_in_date_responded(0.days.ago)
      cases_close_page.click_on "Continue"

      show_page = cases_show_page.case_details

      expect(show_page.retention_details.planned_destruction_date)
        .to have_content("Destruction date")
      expect(show_page.retention_details.planned_destruction_date.date.first.text)
        .to eq(formatted_planned_closure_date(fully_granted_case))

      expect(show_page.retention_details.retention_schedule_state)
        .to have_content("Retention status")
      expect(show_page.retention_details.retention_schedule_state.data.first.text)
        .to eq("Not set")

      expect(show_page.retention_details)
        .not_to have_content("Anonymised on")
    end
  end

private

  def close_case(kase)
    expect(cases_page.case_list.last.status.text).to eq "Ready to dispatch"
    click_link kase.number
    expect(cases_show_page)
      .to have_link("Close case", href: "/cases/offender_sars/#{kase.id}/close")
    click_link "Close case"
  end

  def formatted_planned_closure_date(kase)
    I18n.l(
      kase.retention_schedule.planned_destruction_date,
      format: :default,
    )
  end
end
