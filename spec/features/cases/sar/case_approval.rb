require 'rails_helper'


feature 'cases requiring clearance by disclosure specialist' do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [ team_dacu ] }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }

  def take_case_on_as_discosure_specialist(kase:, expected_approver:)
    incoming_cases_page.load

    expect(incoming_cases_page.case_list.size).to eq 1
    expect(incoming_cases_page.case_list.first.number.text)
      .to have_content kase.number

    case_list_item = incoming_cases_page.case_list.first
    expect(case_list_item).to have_no_highlight_row
    case_list_item.actions.take_on_case.click
    case_list_item.actions.wait_until_success_message_visible
    expect(case_list_item.actions.success_message.text)
      .to include 'Case taken on'
    expect(case_list_item.highlight_row.size).to eq 3
    expect(kase.reload.approvers).to include expected_approver
    case_list_item
  end

  def undo_take_case_on_as_disclosure_specialist(kase, case_list_item)
    expect(case_list_item.highlight_row.size).to eq 3
    case_list_item.actions.undo_assign_link.click
    case_list_item.actions.wait_until_take_on_case_visible
    expect(case_list_item).to have_no_highlight_row
    expect(kase.reload.approvers).to be_blank
  end

  def de_escalate_case_as_disclosure_specialist(kase, case_list_item)
    expect(case_list_item).to have_no_highlight_row
    case_list_item.actions.de_escalate_link.click
    case_list_item.actions.wait_until_undo_de_escalate_link_visible
    expect(case_list_item.highlight_row.size).to eq 3
    expect(kase.reload.approver_assignments).to be_blank
  end

  def undo_de_escalate_case_as_disclosure_specialist(kase, case_list_item)
    expect(case_list_item.highlight_row.size).to eq 3
    case_list_item.actions.undo_de_escalate_link.click
    case_list_item.actions.wait_until_de_escalate_link_visible
    expect(case_list_item).to have_no_highlight_row
    expect(kase.reload.approving_teams).to include team_dacu_disclosure
  end

  scenario 'taking_on, undoing and de-escalating a case as a disclosure specialist', js: true do
    kase = create_and_assign_sar_case user: manager,
                                      responding_team: responding_team,
                                      flag_for_disclosure: true

    login_as disclosure_specialist

    case_list_item = take_case_on_as_discosure_specialist(
      kase: kase,
      expected_approver: disclosure_specialist
    )
    undo_take_case_on_as_disclosure_specialist(kase, case_list_item)
    de_escalate_case_as_disclosure_specialist(kase, case_list_item)
    undo_de_escalate_case_as_disclosure_specialist(kase, case_list_item)
  end

  scenario 'Disclosure Specialist requests amends to a response' do
    kase = create :pending_dacu_clearance_sar, approver: disclosure_specialist, responding_team: responding_team

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Disclosure'

    request_amends kase: kase,
                   expected_action: 'requesting amends for',
                   expected_team: responding_team,
                   expected_status: 'Draft in progress'
    execute_request_amends(expected_flash: "Information Officer has been notified a redraft is needed.")
    go_to_case_details_step(
      kase: kase,
      find_details_page: false,
      expected_team: responding_team,
      expected_history: [
        "#{disclosure_specialist.full_name}#{team_dacu_disclosure.name}Request amends"
      ]
    )
  end
end
