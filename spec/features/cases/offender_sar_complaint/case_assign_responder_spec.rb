require 'rails_helper'

feature 'cases being reassigned to other team members' do
  include Features::Interactions

  given(:accepted_complaint_case) { create :accepted_complaint_case }
  given(:unassigned_complaint_case) { create :offender_sar_complaint }
  given(:responding_team)   { create :team_branston }
  given(:responder)         { responding_team.responders.first }
  given(:another_responder) { create :responder,
                                     responding_teams: [responding_team] }

  scenario 'Responder assigns a case to a team member' do
    login_as responder

    cases_show_page.load(id: unassigned_complaint_case.id)
    go_to_case_assign_team_member expected_users: [responder, another_responder]
    do_case_assign_team_member another_responder
  end

  scenario 'Responder reassigns a case to another team member' do
    login_as responder

    cases_show_page.load(id: accepted_complaint_case.id)
    go_to_case_reassign expected_users: [responder, another_responder]
    do_case_reassign_to another_responder
    go_to_case_reassign expected_users: nil
    do_case_reassign_to responder
  end

  private 

  def go_to_case_assign_team_member(expected_users:)
    cases_show_page.actions.assign_to_team_member.click
    expect(assign_to_team_member_page.team_members.users.size).to eq expected_users.count
    expected_user_names = expected_users.map do |u|
      u.full_name
    end
    expect(assign_to_team_member_page.team_members.users.map(&:text))
      .to match_array expected_user_names
  end

  def do_case_assign_team_member(user)
    assign_to_team_member_page.choose_assignment_user user
    assign_to_team_member_page.confirm_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history.entries.first)
      .to have_text("assigned this case to #{user.full_name}")
  end
  
end
