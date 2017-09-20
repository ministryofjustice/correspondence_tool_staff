require 'rails_helper'

feature 'cases being reassigned to other team members' do
  given(:responding_team)   { create :responding_team }
  given(:responder) { responding_team.responders.first }
  given(:another_responder) { create :responder,
                                     responding_teams: [responding_team] }

  given(:approving_team)   { create :approving_team }
  given(:approver) { approving_team.approvers.first }
  given(:another_approver) { create :approver, approving_team: approving_team }

  given(:disclosure_team)  { find_or_create :team_dacu_disclosure }
  given(:sds)              { disclosure_team.approvers.first }
  given(:another_sds)      { create :disclosure_specialist }

  given(:accepted_case) { create :accepted_case, responder: responder,
                                 responding_team: responding_team }
  given(:flagged_case) { create :case_being_drafted, :flagged_accepted,
                                approving_team: approving_team,
                                approver: approver,
                                responding_team: responding_team }
  given(:sds_flagged_case) { create :case_being_drafted, :flagged_accepted,
                                    approving_team: disclosure_team,
                                    approver: sds,
                                    responding_team: responding_team }
  given(:sds_flagged_case_2) { create :case_being_drafted, :flagged_accepted,
                                      approving_team: disclosure_team,
                                      approver: sds,
                                      responding_team: responding_team }

  def go_to_case_reassign(expected_users:)
    cases_show_page.actions.reassign_user.click
    unless expected_users.nil?
      expect(reassign_user_page.reassign_to.users.size).to eq expected_users.count
      expected_user_names = expected_users.map do |u|
        if u.respond_to? :full_name
          u.full_name
        else
          u.to_s
        end
        # u.respond_to? :full_name ? u.full_name : u.to_s
      end
      expect(reassign_user_page.reassign_to.users.map &:text)
        .to eq expected_user_names
    end
  end

  def do_case_reassign_to(user)
    reassign_user_page.choose_assignment_user user
    reassign_user_page.confirm_button.click
    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history.entries.first)
      .to have_text("re-assigned this case to #{user.full_name}")
  end

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
    go_to_case_reassign expected_users: [approver, another_approver]
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
