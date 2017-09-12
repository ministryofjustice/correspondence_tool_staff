require 'rails_helper'

feature 'cases being reassigned to other team members' do
  given(:responding_team)   { create :responding_team }
  given(:responder) { responding_team.responders.first }
  given(:another_responder) { create :responder, responding_teams: [responding_team] }

  given(:approving_team)   { create :approving_team }
  given(:approver) { approving_team.approvers.first }
  given(:another_approver) { create :approver, approving_team: approving_team }


  given(:accepted_case) { create :accepted_case, responder: responder,
                                 responding_team: responding_team }

  given(:flagged_case) {create :case_being_drafted, :flagged_accepted,
                               approving_team: approving_team, responding_team: responding_team }

  def assign_case_to_another_team_member(team_member)
    cases_show_page.actions.reassign_user.click

    expect(reassign_user_page.reassign_to.users.size).to eq 2
    reassign_user_page.choose_assignment_user team_member

    reassign_user_page.confirm_button.click

    expect(cases_show_page).to be_displayed

  end

  def assign_case_to_themselves(user)
    cases_show_page.actions.reassign_user.click

    expect(reassign_user_page.reassign_to.users.size).to eq 2
    reassign_user_page.choose_assignment_user user

    reassign_user_page.confirm_button.click

    expect(cases_show_page).to be_displayed

  end

  scenario 'Responder assigns a case to another team member' do
    login_as responder

    cases_show_page.load(id: accepted_case.id)

    assign_case_to_another_team_member another_responder

    assign_case_to_themselves responder

  end

  scenario 'Approver assigns a case to another team member' do
    login_as approver

    cases_show_page.load(id: flagged_case.id)

    assign_case_to_another_team_member another_approver

    assign_case_to_themselves approver

  end
end
