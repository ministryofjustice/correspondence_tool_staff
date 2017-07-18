require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given(:dacu_disclosure)             { find_or_create :team_dacu_disclosure }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given(:other_disclosure_specialist) { create :disclosure_specialist }
  given(:press_officer)               { create :press_officer }
  given(:other_press_officer)         { create :press_officer }
  given(:press_office)                { find_or_create :team_press_office }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end
  given(:pending_press_clearance_case) { create :pending_press_clearance_case,
                                                press_officer: press_officer }

  def clear_case(kase:, expected_team:, expected_status:)
    cases_show_page.actions.clear_case.click
    expect(approve_response_page)
      .to be_displayed(id: kase.id)
    expect(approve_response_page.clearance.expectations.team.text)
      .to eq expected_team.name
    expect(approve_response_page.clearance.expectations.status.text)
      .to eq expected_status

  end

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
    expect(cases_show_page.notices.first).to have_content(expected_notice)
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

  def approve_response(kase:)
    approve_response_page.submit_button.click
    expect(open_cases_page).to be_displayed
    expect(open_cases_page.notices.first)
      .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
  end

  def select_case_on_open_cases_page(kase:, expected_team:)
    open_cases_page.click_on kase.number
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq expected_team.name
  end

  scenario 'Disclosure Specialist approves a case that requires Press Office approval' do
    login_as disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)

    clear_case kase: pending_dacu_clearance_case,
               expected_team: press_office,
               expected_status: 'Pending clearance'
    approve_response kase: pending_dacu_clearance_case
    select_case_on_open_cases_page kase: pending_dacu_clearance_case,
                                   expected_team: press_office
  end

  scenario 'a Disclosure Specialist that is not assigned to a case escalates it to press office' do
    login_as other_disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)

    clear_case kase: pending_dacu_clearance_case,
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

    clear_case kase: pending_press_clearance_case,
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
    clear_case kase: pending_press_clearance_case,
               expected_team: pending_press_clearance_case.responding_team,
               expected_status: 'Ready to send'
    approve_response kase: pending_press_clearance_case
    select_case_on_open_cases_page(
      kase: pending_press_clearance_case,
      expected_team: pending_press_clearance_case.responding_team
    )
  end

  scenario 'Press Officer requests amends to a case', js: true do
    stub_s3_uploader_for_all_files!
    response_attachment = Rails.root.join 'spec',
                                          'fixtures',
                                          'response-press-office-comments.docx'

    login_as press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'

    upload_changes_for_redraft kase: pending_press_clearance_case,
                               response_attachments: [response_attachment],
                               expected_team: dacu_disclosure,
                               expected_status: 'Pending clearance'
    submit_changes_for_redraft kase: pending_press_clearance_case,
                               expected_team: dacu_disclosure,
                               expected_status: 'Pending clearance',
                               expected_attachments:
                                 [File.basename(response_attachment)],
                               expected_notice:
                                 'You have uploaded the response for this case.',
                               expected_history:
                                 'Upload response and return for redraft'

  end
end
