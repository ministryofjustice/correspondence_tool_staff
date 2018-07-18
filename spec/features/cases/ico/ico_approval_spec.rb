require 'rails_helper'


feature 'cases requiring clearance by disclosure specialist' do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [ team_dacu ] }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }
  given!(:responding_team)            { create :responding_team }
  given(:responder)                   { responding_team.users.first }


  scenario 'taking_on and undoing a case as a disclosure specialist', js: true do
    kase = create :accepted_ico_foi_case, :flagged,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase: kase)
    undo_taking_case_on_step(kase: kase)
  end

  scenario 'Disclosure Specialist clears a response response', js: true do
    kase = create :pending_dacu_clearance_ico_foi_case,
                  approver: disclosure_specialist,
                  responding_team: responding_team

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Disclosure'

    approve_case_step(kase: kase,
                      expected_team: responding_team,
                      expected_status: 'Ready to send')
    go_to_case_details_step(
      kase: kase,
      expected_team: responding_team,
      expected_history: [
        "#{disclosure_specialist.full_name} #{team_dacu_disclosure.name} Response cleared"
      ]
    )
  end

  scenario 'upload a response and return for redraft', js: true do
    kase = create :pending_dacu_clearance_ico_foi_case, approver: disclosure_specialist

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

  scenario 'upload a response and approve', js: true do
    kase = create :pending_dacu_clearance_ico_foi_case, approver: disclosure_specialist

    login_as disclosure_specialist
    cases_show_page.load(id: kase.id)
    cases_show_page.actions.upload_approve.click

    expect(cases_new_response_upload_page).to be_displayed
    expect_any_instance_of(CasesController).to receive(:upload_responses)
    cases_new_response_upload_page.upload_response_button.click
    upload_and_approve_response_as_dacu_disclosure_specialist(kase.reload, disclosure_specialist)

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.copy.text).to eq 'Ready to send'
    expect(cases_show_page.case_status.details.who_its_with.text).to eq kase.responding_team.name
  end
end
