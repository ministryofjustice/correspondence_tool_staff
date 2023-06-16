require "rails_helper"

feature "Assigning a SAR case to a new team" do
  given(:disclosure_bmt_user) { find_or_create :disclosure_bmt_user }
  given!(:responding_team) { create :responding_team }

  background do
    login_as disclosure_bmt_user
  end

  scenario "re-assigning a closed SAR case" do
    closed_case = create :closed_sar

    cases_show_page.load(id: closed_case.id)
    cases_show_page.actions.assign_to_new_team.click

    assign_case_step business_unit: responding_team,
                     assigning_page: assign_to_new_team_page,
                     expected_status: "Closed",
                     expected_flash_msg: "Case has been assigned to #{responding_team.name}"
  end

  scenario "re-assigning a SAR case that is being drafted" do
    responding_team

    accepted_case = create :accepted_sar

    cases_show_page.load(id: accepted_case.id)
    cases_show_page.actions.assign_to_new_team.click

    assign_case_step business_unit: responding_team,
                     assigning_page: assign_to_new_team_page,
                     expected_status: "To be accepted",
                     expected_flash_msg: "Case has been assigned to #{responding_team.name}"
  end

  scenario "re-assigning a trigger SAR case that is being drafted" do
    responding_team

    accepted_case = create :accepted_sar

    cases_show_page.load(id: accepted_case.id)
    cases_show_page.actions.assign_to_new_team.click

    assign_case_step business_unit: responding_team,
                     assigning_page: assign_to_new_team_page,
                     expected_status: "To be accepted",
                     expected_flash_msg: "Case has been assigned to #{responding_team.name}"
  end
end
