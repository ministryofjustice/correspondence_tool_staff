require "rails_helper"

feature "cases being reassigned to other team members" do
  include Features::Interactions

  given(:responding_team)   { find_or_create :foi_responding_team }
  given(:responder)         { responding_team.responders.first }
  given(:another_responder) do
    create :responder,
           responding_teams: [responding_team]
  end

  given(:approving_team)   { find_or_create :team_dacu_disclosure }
  given(:approver)         { find_or_create :disclosure_specialist }
  given(:another_approver) { create :approver, approving_team: }

  given(:sds)              { create :approver, approving_team: }
  given(:another_sds)      { create :approver, approving_team: }
  given(:accepted_case)    { create :accepted_ico_foi_case, :flagged_accepted }

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

    cases_show_page.load(id: accepted_case.id)
    go_to_case_reassign expected_users: ["#{approver.full_name} (1 open case)",
                                         "#{another_approver.full_name} (0 open cases)",
                                         "#{sds.full_name} (0 open cases)"]
    do_case_reassign_to another_approver
    go_to_case_reassign expected_users: nil
    do_case_reassign_to approver
  end
end
