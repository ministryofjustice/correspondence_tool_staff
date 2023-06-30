require "rails_helper"

feature "cases being reassigned to other team members" do
  include Features::Interactions

  given(:accepted_complaint_case) { create :accepted_complaint_case }
  given(:unassigned_complaint_case) { create :offender_sar_complaint }
  given(:responding_team)   { create :team_branston }
  given(:responder)         { responding_team.responders.first }
  given(:another_responder) do
    create :responder,
           responding_teams: [responding_team]
  end

  scenario "Responder assigns a case to a team member" do
    login_as responder

    cases_show_page.load(id: unassigned_complaint_case.id)
    go_to_case_assign_team_member expected_users: [responder, another_responder]
    not_choose_member_and_continue(assign_to_team_member_page)
    click_assign_memeber_btn
    do_case_assign_team_member another_responder
  end

  scenario "Responder reassigns a case to another team member" do
    login_as responder

    cases_show_page.load(id: accepted_complaint_case.id)
    go_to_case_reassign expected_users: [responder, another_responder]
    not_choose_member_and_continue(reassign_user_page)
    click_reassign_member_btn
    do_case_reassign_to another_responder
    go_to_case_reassign expected_users: nil
    do_case_reassign_to responder
  end

private

  def go_to_case_assign_team_member(expected_users:)
    cases_show_page.actions.assign_to_team_member.click
    expect(assign_to_team_member_page.team_members.users.size).to eq expected_users.count
    expected_user_names = expected_users.map(&:full_name)
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

  def not_choose_member_and_continue(page_object)
    page_object.confirm_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "No changes were made"
  end

  def click_assign_memeber_btn
    cases_show_page.actions.assign_to_team_member.click
  end

  def click_reassign_member_btn
    cases_show_page.actions.reassign_user.click
  end
end
