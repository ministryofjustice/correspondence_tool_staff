require 'rails_helper'

feature 'cases being reassigned to other team members' do
  include Features::Interactions

  given(:responding_team)   { create :responding_team }
  given(:responder) { responding_team.responders.first }
  given(:another_responder) { create :responder,
                                     responding_teams: [responding_team] }

  given(:approving_team)   { find_or_create :team_dacu_disclosure }
  given(:approver)         { create :disclosure_specialist, approving_team: approving_team }
  given(:another_approver) { create :approver, approving_team: approving_team }

  # given(:disclosure_team)  { find_or_create :team_dacu_disclosure }
  given(:sds)              { approving_team.approvers.first }
  given(:another_sds)      { create :disclosure_specialist }

  given(:accepted_case) { create :accepted_case, responder: responder,
                                 responding_team: responding_team }
  given(:flagged_case) { create :case_being_drafted, :flagged_accepted,
                                approving_team: approving_team,
                                approver: approver,
                                responding_team: responding_team }
  given(:sds_flagged_case) { create :case_being_drafted, :flagged_accepted,
                                    approving_team: approving_team,
                                    approver: sds,
                                    responding_team: responding_team }
  given(:sds_flagged_case_2) { create :case_being_drafted, :flagged_accepted,
                                      approving_team: approving_team,
                                      approver: sds,
                                      responding_team: responding_team }

  scenario 'Responder assigns a case to another team member' do
    login_as responder

    cases_show_page.load(id: accepted_case.id)
    go_to_case_reassign expected_users: [responder, another_responder]
    do_case_reassign_to another_responder
    go_to_case_reassign expected_users: nil
    do_case_reassign_to responder
  end

  scenario 'Approver assigns a case to another team member' do
    login_as approver

    cases_show_page.load(id: flagged_case.id)
    go_to_case_reassign expected_users: ["#{approver.full_name} (1 open case)",
                                         "#{another_approver.full_name} (0 open cases)",
                                         "#{sds.full_name} (0 open cases)"]
    do_case_reassign_to another_approver
    go_to_case_reassign expected_users: nil
    do_case_reassign_to approver
  end

  scenario 'Disclosure Specialist assigns a case to a team member' do
    sds_flagged_case_2
    login_as sds
    another_sds

    cases_show_page.load(id: sds_flagged_case.id)

    go_to_case_reassign expected_users: [
                          "#{sds.full_name} (2 open cases)",
                          "#{another_sds.full_name} (0 open cases)",
                        ]

    do_case_reassign_to another_sds
  end
end
