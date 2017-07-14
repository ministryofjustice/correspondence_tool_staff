require 'rails_helper'

feature 'cases requiring clearance by disclosure specialist' do
  given(:manager)                     { create :manager }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given(:other_disclosure_specialist) { create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { create :team_dacu_disclosure }
  given(:responder)                   { responding_team.users.first }

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

  def create_flagged_case_and_assign_to_team
    login_as manager

    cases_page.load
    cases_page.new_case_button.click

    create_case(flag_for_clearance: true)
    assign_case_to_team(team: responding_team)
    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history.entries.last.text)
      .to include('Flag for clearance')

    Case.last
  end

  def accept_case_as_kilo(kase)
    login_as responder
    assignments_edit_page.load(case_id: kase.id, id: kase.responder_assignment.id)
    assignments_edit_page.accept_radio.click
    assignments_edit_page.confirm_button.click
  end

  def upload_response_as_kilo(kase, kilo)
    upload_response_with_action_param(kase, kilo, 'upload-flagged')
  end

  def upload_and_approve_response_as_dacu_disclosure_specialist(kase, dd_specialist)
    upload_response_with_action_param(kase, dd_specialist, 'upload-approve')
  end

  def upload_response_and_send_for_redraft_as_disclosure_specialist(kase, dd_specialist)
    upload_response_with_action_param(kase, dd_specialist, 'upload-redraft')
  end

  def upload_response_with_action_param(kase, user, action)
    uploads_key = "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"
    params = ActionController::Parameters.new(
      {
        "type"=>"response",
        "uploaded_files"=>[uploads_key],
        "id"=>kase.id.to_s,
        "controller"=>"cases",
        "action"=>"upload_responses"}
    )
    rus = ResponseUploaderService.new(kase, user, params, action)
    uploader = rus.instance_variable_get :@uploader
    allow(uploader).to receive(:move_uploaded_file)
    allow(uploader).to receive(:remove_leftover_upload_files)
    rus.upload!
  end

  scenario 'taking_on, undoing and de-escalating a case as a disclosure specialist', js: true do
    kase = create_flagged_case_and_assign_to_team

    login_as disclosure_specialist

    case_list_item = take_case_on_as_discosure_specialist(
      kase: kase,
      expected_approver: disclosure_specialist
    )
    undo_take_case_on_as_disclosure_specialist(kase, case_list_item)
    de_escalate_case_as_disclosure_specialist(kase, case_list_item)
    undo_de_escalate_case_as_disclosure_specialist(kase, case_list_item)
  end

  scenario 'approving a case as a disclosure specialist', js: true do
    kase = create_flagged_case_and_assign_to_team
    accept_case_as_kilo(kase)
    upload_response_as_kilo(kase.reload, responder)

    login_as disclosure_specialist
    take_case_on_as_discosure_specialist(
      kase: kase,
      expected_approver: disclosure_specialist
    )
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).to have_clear_case
    cases_show_page.actions.clear_case.click

    expect(approve_response_page).to be_displayed
    approve_response_page.submit_button.click
    expect(kase.reload.current_state).to eq 'awaiting_dispatch'
  end

  scenario 'approving a case as a disclosure specialist not assigned directly to the case', js: true do
    kase = create_flagged_case_and_assign_to_team
    accept_case_as_kilo(kase)
    upload_response_as_kilo(kase.reload, responder)

    login_as other_disclosure_specialist
    take_case_on_as_discosure_specialist(
      kase: kase,
      expected_approver: other_disclosure_specialist
    )
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).to have_clear_case
    cases_show_page.actions.clear_case.click

    expect(approve_response_page).to be_displayed
    approve_response_page.submit_button.click
    expect(kase.reload.current_state).to eq 'awaiting_dispatch'
  end

  scenario 'upload a response and approve case as a disclosure specialist', js: true do
    kase = create_flagged_case_and_assign_to_team
    accept_case_as_kilo(kase)
    upload_response_as_kilo(kase.reload, responder)

    login_as disclosure_specialist
    take_case_on_as_discosure_specialist(
      kase: kase,
      expected_approver: disclosure_specialist
    )
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).to have_upload_approve
    cases_show_page.actions.upload_approve.click

    expect(cases_new_response_upload_page).to be_displayed

    expect_any_instance_of(CasesController).to receive(:upload_responses)
    cases_new_response_upload_page.upload_response_button.click
    upload_and_approve_response_as_dacu_disclosure_specialist(kase.reload, disclosure_specialist)

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.copy.text).to eq 'Ready to send'
    expect(cases_show_page.case_status.details.who_its_with.text).to eq responding_team.name
  end

  scenario 'upload a response and return for redraft', js: true do
    kase = create :pending_dacu_clearance_case, approver: disclosure_specialist

    login_as disclosure_specialist
    cases_show_page.load(id: kase.id)
    cases_show_page.actions.upload_redraft.click

    expect(cases_new_response_upload_page).to be_displayed
    expect_any_instance_of(CasesController).to receive(:upload_responses)
    cases_new_response_upload_page.upload_response_button.click
    upload_response_and_send_for_redraft_as_disclosure_specialist(kase.reload, disclosure_specialist)

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.copy.text).to eq 'Draft in progress'
    expect(cases_show_page.case_status.details.who_its_with.text).to eq kase.responding_team.name
  end
end
