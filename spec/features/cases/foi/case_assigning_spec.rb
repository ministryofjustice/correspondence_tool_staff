require "rails_helper"

feature "Assigning a case from the detail view" do
  given(:kase)            { create(:case) }
  given(:responder)       { find_or_create(:foi_responder) }
  given(:responding_team) { responder.responding_teams.first }
  given(:manager)         { create(:manager) }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:assignment)      { kase.responder_assignment }

  before do
    responding_team
    login_as manager
  end

  scenario "assigning a new case" do
    visit case_path(kase)
    expect(cases_show_page).to(
      have_link("Assign to a responder", href: new_case_assignment_path(kase)),
    )

    click_link "Assign to a responder"

    assign_case_step business_unit: responder.responding_teams.first,
                     expected_flash_msg: "Case successfully assigned"

    newest_assignment = Assignment.last

    kase.reload
    expect(kase.current_state).to eq "awaiting_responder"
    expect(kase.assignments).to include newest_assignment

    expect(newest_assignment).to have_attributes(
      role: "responding",
      team: responding_team,
      user_id: nil,
      case: kase,
      state: "pending",
    )
  end

  context "when case has been rejected" do
    given(:kase) { create :assigned_case, responding_team: }

    before do
      responding_team
      assignment.reject responder, "No thanks"
    end

    scenario "assigner reassigns rejected case" do
      visit case_path(kase)
      expect(cases_show_page).to(
        have_link("Assign to a responder", href: new_case_assignment_path(kase)),
      )

      click_link "Assign to a responder"

      assign_case_step business_unit: responder.responding_teams.first,
                       expected_flash_msg: "Case successfully assigned"

      newest_assignment = Assignment.last

      kase.reload
      expect(kase.current_state).to eq "awaiting_responder"
      expect(kase.assignments).to include newest_assignment

      expect(newest_assignment).to have_attributes(
        role: "responding",
        team: responding_team,
        user_id: nil,
        case: kase,
        state: "pending",
      )
    end
  end
end
