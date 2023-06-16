require "rails_helper"

feature "Upload response" do
  given(:unassigned_manager) { create(:manager) }
  given(:tmm_kase)           { create(:closed_sar, :clarification_required) }
  given(:kase)           { create(:closed_sar) }
  given(:responder)      { tmm_kase.responding_team.users.first }
  given(:manager) { tmm_kase.managing_team.users.first }
  given(:manager_teammate) do
    create :manager, managing_teams: manager.managing_teams
  end

  context "Upload response for tmm sar case" do
    scenario "as the assigned manager" do
      login_as manager
      cases_show_page.load(id: tmm_kase.id)
      cases_show_page.actions.upload_response.click
      expect(cases_upload_responses_page).to be_displayed
    end

    scenario "as a manager on the same team" do
      login_as manager_teammate
      cases_show_page.load(id: tmm_kase.id)
      cases_show_page.actions.upload_response.click
      expect(cases_upload_responses_page).to be_displayed
    end

    scenario "as a manager that isn't assigned to the case" do
      login_as unassigned_manager
      cases_show_page.load(id: tmm_kase.id)
      expect(cases_show_page).not_to have_link("Upload response")
    end

    scenario "as an assigned responder" do
      login_as responder
      cases_show_page.load(id: tmm_kase.id)
      expect(cases_show_page).not_to have_link("Upload response")
    end
  end

  context "Upload response for non-tmm sar case" do
    scenario "as the assigned manager" do
      login_as manager
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).not_to have_link("Upload response")
    end

    scenario "as an assigned responder" do
      login_as responder
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).not_to have_link("Upload response")
    end
  end
end
