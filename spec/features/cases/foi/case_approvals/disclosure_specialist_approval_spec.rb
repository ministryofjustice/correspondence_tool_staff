require 'rails_helper'


feature 'cases requiring clearance by disclosure specialist' do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [ team_dacu ] }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given(:other_disclosure_specialist) { create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }
  given(:responder)                   { responding_team.users.first }

  def upload_and_approve_response_as_dacu_disclosure_specialist(kase, dd_specialist)
    upload_response_with_action_param(kase, dd_specialist, 'upload-approve')
  end

  def upload_response_and_send_for_redraft_as_disclosure_specialist(kase, dd_specialist)
    upload_response_with_action_param(kase, dd_specialist, 'upload-redraft')
  end

  def upload_response_with_action_param(kase, user, action)
    uploads_key = "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"
    raw_params = ActionController::Parameters.new(
      {
        "type"=>"response",
        "uploaded_files"=>[uploads_key],
        "id"=>kase.id.to_s,
        "controller"=>"cases",
        "upload_comment" => "I've uploaded it",
        "action"=>"upload_responses"}
    )
    params = BypassParamsManager.new(raw_params)
    rus = ResponseUploaderService.new(kase, user, params, action)
    uploader = rus.instance_variable_get :@uploader
    allow(uploader).to receive(:move_uploaded_file)
    allow(uploader).to receive(:remove_leftover_upload_files)
    rus.upload!
  end

  scenario 'taking_on, undoing and de-escalating a case as a disclosure specialist', js: true do
    kase = create :case_being_drafted, :flagged,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase: kase)
    undo_taking_case_on_step(kase: kase)
    de_escalate_case_step(kase: kase)
    expect(kase.reload.approver_assignments).to be_blank
    undo_de_escalate_case_step(kase: kase)
  end

  scenario 'approving a case as a disclosure specialist not assigned directly to the case', js: true do
    kase = create :pending_dacu_clearance_case,
                  responder: responder,
                  responding_team: responding_team,
                  approver: disclosure_specialist

    login_as other_disclosure_specialist
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).not_to have_clear_case
  end

  scenario 'upload a response and approve case as a disclosure specialist', js: true do
    kase = create :pending_dacu_clearance_case,
                  responder: responder,
                  responding_team: responding_team,
                  approver: disclosure_specialist

    login_as disclosure_specialist

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

  scenario 'upload a response and remove clearance as a disclosure specialist', js: true do
    kase = create :pending_dacu_clearance_case,
                  responder: responder,
                  responding_team: responding_team,
                  approver: disclosure_specialist

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.clearance_levels.basic_details.dacu_disclosure.remove_clearance.text).to eq(
      'Remove clearance')
    cases_show_page.clearance_levels.basic_details.dacu_disclosure.remove_clearance.click
    expect(page).to have_current_path(remove_clearance_case_path(kase))
    fill_in 'Reason for removing clearance', :with => "reason"
    cases_remove_clearance_form_page.submit_button.click
    expect(cases_show_page.notice.text).to eq "Clearance removed for this case."
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

  scenario 'approving a case and bypassing press and private clearance', js: true do
    kase = create :pending_dacu_clearance_case_flagged_for_press_and_private, approver: disclosure_specialist
    responding_team = kase.responding_team
    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    approve_case_with_bypass(kase: kase, expected_team: responding_team, expected_status: 'Ready to send')
  end
end
