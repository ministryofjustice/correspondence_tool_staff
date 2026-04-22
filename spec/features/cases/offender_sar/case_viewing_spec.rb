require "rails_helper"

feature "Viewing for cases" do
  given!(:responder) { find_or_create :branston_user }
  given!(:responder_and_team_admin_and_manager) do
    find_or_create :responder_and_team_admin_and_manager, responding_teams: responder.responding_teams
  end

  describe "open cases" do
    given!(:kase_earlier) { create :offender_sar_case, received_date: 3.days.ago, responder: responder_and_team_admin_and_manager }
    given!(:kase)         { create :offender_sar_case, responder: responder }

    scenario "View open-cases tab - choice of ordering the result" do
      login_as responder

      cases_page.load
      cases_page.primary_navigation.all_open_cases.click
      expect(cases_page.case_list.count).to eq 2
      expect(cases_page.case_list.first.number).to have_text kase_earlier.number
      expect(cases_page.case_list.second.number).to have_text kase.number

      click_on "Show newest cases first"

      expect(cases_page.case_list.count).to eq 2
      expect(cases_page.case_list.first.number).to have_text kase.number
      expect(cases_page.case_list.second.number).to have_text kase_earlier.number
    end

    scenario "when viewing a case as a responder" do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
      expect(cases_show_page).not_to have_stop_the_clock
      expect(cases_show_page).not_to have_extend_sar_deadline
    end

    scenario "when viewing a case as a responder, team_admin and manager" do
      login_as responder_and_team_admin_and_manager

      cases_show_page.load id: kase_earlier.id

      expect(cases_show_page).to be_displayed(id: kase_earlier.id)
      expect(cases_show_page).to have_stop_the_clock
      expect(cases_show_page).to have_extend_sar_deadline
    end
  end

  describe "when stopped case" do
    context "and allowed to restart the clock" do
      given(:responder_and_team_admin) do
        create :responder_and_team_admin, responding_teams: responder.responding_teams
      end

      given!(:kase) do
        create :offender_sar_case, :stopped, responder: responder_and_team_admin
      end

      scenario "can restart as a responder manager" do
        login_as responder_and_team_admin

        cases_show_page.load id: kase.id

        expect(cases_show_page).to be_displayed(id: kase.id)
        expect(cases_show_page).to have_restart_the_clock
        expect(cases_show_page.new_message).to have_add_button
      end
    end

    context "and not allowed to restart the clock" do
      given!(:kase) do
        create :offender_sar_case, :stopped, responder: responder
      end

      scenario "cannot restart as a responder" do
        login_as responder

        cases_show_page.load id: kase.id

        expect(cases_show_page).to be_displayed(id: kase.id)
        expect(cases_show_page).not_to have_restart_the_clock
        expect(cases_show_page.new_message).to have_add_button
      end
    end
  end
end
