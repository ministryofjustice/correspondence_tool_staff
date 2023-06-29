require "rails_helper"

feature "deactivating users" do
  given!(:team_admin)       { find_or_create :team_admin }
  given!(:manager)          { find_or_create :disclosure_bmt_user }
  given!(:business_unit)    { find_or_create :foi_responding_team }
  given!(:responder)        { create :responder, responding_teams: [business_unit] }
  given!(:user_with_cases)  { find_or_create :foi_responder }
  given!(:live_case)        { create :accepted_case }
  given!(:responded_case)   do
    create :responded_case,
           responder: user_with_cases,
           responding_team: business_unit,
           received_date: 5.days.ago
  end

  before do
    business_unit.team_admins << team_admin
  end

  scenario "manager deactivates a responder with no live cases" do
    login_as manager

    teams_show_page.load(id: business_unit.id)
    information_officer = teams_show_page.row_for_information_officer(responder.email)
    information_officer.actions.click

    expect(users_edit_page).to be_displayed

    users_edit_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq responder

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(responder.email, responder.password)
    expect(login_page.error_message).to have_content "Invalid email or password."
  end

  scenario "manager deactivates responder with live cases" do
    login_as manager

    check_key_fields_before_deactivate_user_for_open_case
    check_key_fields_for_responded_case

    teams_show_page.load(id: business_unit.id)
    information_officer = teams_show_page.row_for_information_officer(user_with_cases.email)
    information_officer.actions.click

    expect(users_edit_page).to be_displayed

    users_edit_page.deactivate_user_button.click
    users_destroy_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq user_with_cases

    check_key_fields_after_deactivate_user_for_open_case
    check_key_fields_for_responded_case

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(user_with_cases.email, user_with_cases.password)
    expect(login_page.error_message).to have_content "Invalid email or password."
  end

  scenario "user manaing team members deactivates a responder with no live cases" do
    login_as team_admin

    teams_show_page.load(id: business_unit.id)
    information_officer = teams_show_page.row_for_information_officer(responder.email)
    information_officer.actions.click

    expect(users_edit_page).to be_displayed

    users_edit_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq responder

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(responder.email, responder.password)
    expect(login_page.error_message).to have_content "Invalid email or password."
  end

  scenario "user manaing team members deactivates responder with live cases" do
    login_as team_admin

    check_key_fields_before_deactivate_user_for_open_case
    check_key_fields_for_responded_case

    teams_show_page.load(id: business_unit.id)
    information_officer = teams_show_page.row_for_information_officer(user_with_cases.email)
    information_officer.actions.click

    expect(users_edit_page).to be_displayed

    users_edit_page.deactivate_user_button.click
    users_destroy_page.deactivate_user_button.click
    expect(teams_show_page).to be_displayed
    expect(teams_show_page.flash_notice.text).to eq "Team member has been deactivated"
    expect(information_officer).not_to eq user_with_cases

    check_key_fields_after_deactivate_user_for_open_case
    check_key_fields_for_responded_case

    # A deactivated user cannot sign in
    cases_page.user_card.signout.click
    login_page.log_in(user_with_cases.email, user_with_cases.password)
    expect(login_page.error_message).to have_content "Invalid email or password."
  end

private

  def check_key_fields_before_deactivate_user_for_open_case
    expect(live_case.responder_assignment.state).to eq "accepted"
    expect(live_case.responder).to eq user_with_cases
    expect(live_case.current_state).to eq "drafting"
    expect(live_case.responding_team).to eq business_unit
  end

  def check_key_fields_after_deactivate_user_for_open_case
    live_case.reload
    expect(live_case.responder_assignment.state).to eq "pending"
    expect(live_case.responding_team).to eq business_unit
    expect(live_case.responder).to eq nil
    expect(live_case.current_state).to eq "awaiting_responder"
  end

  def check_key_fields_for_responded_case
    responded_case.reload
    expect(responded_case.responder_assignment.state).to eq "accepted"
    expect(responded_case.responder).to eq user_with_cases
    expect(responded_case.current_state).to eq "responded"
    expect(responded_case.responder_assignment.state).to eq "accepted"
  end
end
