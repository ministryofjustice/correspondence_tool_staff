require "rails_helper"

feature "cases being reassigned to other team members" do
  include Features::Interactions

  given(:user_with_multiple_roles) { create :approver_responder_manager, approving_team: }
  given(:responding_team)   { create :foi_responding_team }
  given(:responder)         { responding_team.responders.first }
  given(:another_responder) do
    create :responder,
           responding_teams: [responding_team]
  end

  given(:approving_team)   { find_or_create :team_dacu_disclosure }
  given(:approver)         { find_or_create :disclosure_specialist }
  given(:another_approver) { create :approver, approving_team: }

  given(:accepted_case)    { create :accepted_case }
  given(:flagged_case)     { create :case_being_drafted, :flagged_accepted }
  given(:flagged_case_2)   { create :case_being_drafted, :flagged_accepted }

  scenario "Responder assigns a case to another team member" do
    login_as responder

    cases_show_page.load(id: accepted_case.id)
    go_to_case_reassign expected_users: [responder, another_responder]
    do_case_reassign_to another_responder
    go_to_case_reassign expected_users: nil
    do_case_reassign_to responder
  end

  scenario "Approver assigns a case to another team member" do
    login_as approver

    cases_show_page.load(id: flagged_case.id)
    go_to_case_reassign expected_users: ["#{approver.full_name} (1 open case)",
                                         "#{another_approver.full_name} (0 open cases)"]
    do_case_reassign_to another_approver
    go_to_case_reassign expected_users: nil
    do_case_reassign_to approver
  end

  scenario "Approver with multiple roles assigns a case to another team member" do
    another_approver
    kase = create(:case_being_drafted, :flagged_accepted,
                  approving_team:,
                  approver: user_with_multiple_roles,
                  responding_team:)
    login_as user_with_multiple_roles

    cases_show_page.load(id: kase.id)
    cases_show_page.actions.reassign_user.click
    do_case_reassign_to another_approver
  end

  scenario "Disclosure Specialist assigns a case to a team member" do
    login_as approver
    another_approver

    flagged_case_2
    cases_show_page.load(id: flagged_case.id)

    go_to_case_reassign expected_users: [
      "#{approver.full_name} (2 open cases)",
      "#{another_approver.full_name} (0 open cases)",
    ]

    do_case_reassign_to another_approver
  end
end
