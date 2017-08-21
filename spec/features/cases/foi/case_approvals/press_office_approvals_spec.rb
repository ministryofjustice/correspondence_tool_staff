require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given(:dacu_disclosure)             { find_or_create :team_dacu_disclosure }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given(:other_disclosure_specialist) { create :disclosure_specialist }
  given!(:press_officer)              { create :press_officer }
  given(:other_press_officer)         { create :press_officer }
  given!(:press_office)               { find_or_create :team_press_office }
  given!(:private_office)             { find_or_create :team_private_office }
  given!(:private_officer)            { create :private_officer,
                                               full_name: 'Primrose Offord' }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end
  given(:pending_press_clearance_case) { create :pending_press_clearance_case,
                                                press_officer: press_officer }
  given(:case_available_for_taking_on) { create :case_being_drafted,
                                                created_at: 1.business_day.ago }

  def upload_changes_for_redraft(kase:,
                                 response_attachments:,
                                 expected_team:,
                                 expected_status:)
    cases_show_page.actions.upload_redraft.click
    expect(cases_new_response_upload_page).to be_displayed(id: kase.id)
    expect(cases_new_response_upload_page.clearance.expectations.team.text)
      .to eq expected_team.name
    expect(cases_new_response_upload_page.clearance.expectations.status.text)
      .to eq expected_status
    response_attachments.each do |file|
      cases_new_response_upload_page.drop_in_dropzone file
    end
  end

  # rubocop:disable Metrics/ParameterLists
  def submit_changes_for_redraft(kase:,
                                 expected_notice:,
                                 expected_team:,
                                 expected_status:,
                                 expected_attachments:,
                                 expected_history:)
    cases_new_response_upload_page.upload_response_button.click
    expect(cases_show_page).to be_displayed(id: kase.id)
    expect(cases_show_page.notice).to have_content(expected_notice)
    expect(cases_show_page.case_status.details.who_its_with)
      .to have_text(expected_team.name)
    expect(cases_show_page.case_status.details.copy)
      .to have_text(expected_status)
    expected_attachments.each do |attachment|
      expect(cases_show_page.case_attachments.first.collection.first.filename)
        .to have_text(attachment)
    end
    expect(cases_show_page.case_history.entries.first)
      .to have_text(expected_history)
  end
  # rubocop:enable Metrics/ParameterLists

  scenario 'Press Officer taking on a case', js: true do
    private_office
    dacu_disclosure
    private_officer
    case_available_for_taking_on

    login_as press_officer
    incoming_cases_page.load

    case_row = incoming_cases_page.case_list.first
    expect(case_row.number).to have_text case_available_for_taking_on.number
    case_row.actions.take_on_case.click
    expect(case_row.actions.success_message).to have_text 'Case taken on'

    select_case_on_incoming_cases_page(
      kase: case_available_for_taking_on,
      expected_history: [
        'Primrose Offord Clearance level added'
      ]
    )

    _case_not_for_press_office_open_cases = create :case_being_drafted,
                                                   :flagged_accepted,
                                                   :private_office
    open_cases_page.load
    expect(open_cases_page.case_list.first.number)
      .to have_text case_available_for_taking_on.number
    expect(open_cases_page.case_list.count).to eq 1
  end

  scenario 'Disclosure Specialist approves a case that requires Press Office approval' do
    login_as disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)

    approve_case kase: pending_dacu_clearance_case,
                 expected_team: press_office,
                 expected_status: 'Pending clearance'
    approve_response kase: pending_dacu_clearance_case
    select_case_on_open_cases_page kase: pending_dacu_clearance_case,
                                   expected_team: press_office
  end

  scenario 'a Disclosure Specialist not assigned to a case approve it for press office' do
    login_as other_disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)

    approve_case kase: pending_dacu_clearance_case,
                 expected_team: press_office,
                 expected_status: 'Pending clearance'
    approve_response kase: pending_dacu_clearance_case
    select_case_on_open_cases_page kase: pending_dacu_clearance_case,
                                   expected_team: press_office
  end

  scenario 'Press Officer approves a case' do
    login_as press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'

    approve_case kase: pending_press_clearance_case,
                 expected_team: pending_press_clearance_case.responding_team,
                 expected_status: 'Ready to send'
    approve_response kase: pending_press_clearance_case
    select_case_on_open_cases_page(
      kase: pending_press_clearance_case,
      expected_team: pending_press_clearance_case.responding_team
    )
  end

  scenario 'different Press Officer from same team approving a case' do
    login_as other_press_officer
    cases_show_page.load(id: pending_press_clearance_case.id)
    approve_case kase: pending_press_clearance_case,
                 expected_team: pending_press_clearance_case.responding_team,
                 expected_status: 'Ready to send'
    approve_response kase: pending_press_clearance_case
    select_case_on_open_cases_page(
      kase: pending_press_clearance_case,
      expected_team: pending_press_clearance_case.responding_team
    )
  end

  scenario 'Press Officer requests amends to a response' do
    login_as press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'

    request_amends kase: pending_press_clearance_case,
                   expected_action: 'requesting amends for',
                   expected_team: dacu_disclosure,
                   expected_status: 'Pending clearance'
    execute_request_amends kase: pending_press_clearance_case
    select_case_on_open_cases_page(
      kase: pending_press_clearance_case,
      expected_team: dacu_disclosure,
      expected_history: ["#{press_officer.full_name}Request amends"]
    )
  end
end
