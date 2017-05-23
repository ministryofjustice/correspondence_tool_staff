require 'rails_helper'

feature 'cases requiring clearance by disclosure specialist' do
  given(:manager) { create :manager }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:responding_team) { create :responding_team }
  given!(:team_dacu_disclosure) { create :team_dacu_disclosure }

  def create_case(flag_for_clearance: false)
    expect(cases_new_page).to be_displayed
    cases_new_page.fill_in_case_details
    cases_new_page.choose_flag_for_disclosure_specialists(
      flag_for_clearance ? 'yes' : 'no'
    )
    cases_new_page.submit_button.click
  end

  def assign_case_to_team(team:)
    expect(assignments_new_page).to be_displayed
    assignments_new_page.choose_assignment_team team
    assignments_new_page.create_and_assign_case.click
  end

  scenario 'flagging a case on creation', js: true do
    login_as manager

    cases_page.load
    cases_page.new_case_button.click

    create_case(flag_for_clearance: true)
    assign_case_to_team(team: responding_team)
    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history.entries.last.text)
      .to include('Flag for clearance')

    kase = Case.last

    ## DISCLOSURE SPECIALIST ###############################
    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1
    expect(incoming_cases_page.case_list.first.number.text)
      .to have_content kase.number

    ## TAKE CASE ON ##################################################
    case_list_item = incoming_cases_page.case_list.first
    expect(case_list_item).to have_no_highlight_row
    case_list_item.actions.take_on_case.click
    case_list_item.actions.wait_until_success_message_visible
    expect(case_list_item.actions.success_message.text)
      .to include 'Moved to open cases'
    expect(case_list_item.highlight_row.size).to eq 3
    expect(kase.reload.approver).to eq disclosure_specialist

    ## UNDO TAKE CASE ON ############################################
    expect(case_list_item.highlight_row.size).to eq 3
    case_list_item.actions.undo_assign_link.click
    case_list_item.actions.wait_until_take_on_case_visible
    expect(case_list_item).to have_no_highlight_row
    expect(kase.reload.approver).to be_nil

    ## DE-ESCALATE CASE #############################################
    expect(case_list_item).to have_no_highlight_row
    case_list_item.actions.de_escalate_link.click
    case_list_item.actions.wait_until_undo_de_escalate_link_visible
    expect(case_list_item.highlight_row.size).to eq 3
    expect(kase.reload.approver_assignment).to be_blank

    ## UNDO DE-ESCALATE CASE ########################################
    expect(case_list_item.highlight_row.size).to eq 3
    case_list_item.actions.undo_de_escalate_link.click
    case_list_item.actions.wait_until_de_escalate_link_visible
    expect(case_list_item).to have_no_highlight_row
    expect(kase.reload.approving_team).to eq team_dacu_disclosure
  end
end
