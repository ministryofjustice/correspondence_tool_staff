require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given!(:dacu_disclosure) {find_or_create :team_dacu_disclosure}
  given(:disclosure_specialist) {create :disclosure_specialist}
  given(:other_disclosure_specialist) {create :disclosure_specialist}
  given!(:press_office) {find_or_create :team_press_office}
  given!(:press_officer) {create :press_officer,
                                 full_name: 'Preston Offman'}
  given!(:private_office) {find_or_create :team_private_office}
  given!(:private_officer) {create :private_officer}
  given(:other_private_officer) {create :private_officer}
  given(:case_available_for_taking_on) {create :case_being_drafted,
                                               created_at: 1.business_day.ago}
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist:       disclosure_specialist
  end
  given(:pending_press_clearance_case) {create :pending_press_clearance_case,
                                               :private_office}
  given(:pending_private_clearance_case) {create :pending_private_clearance_case}

  scenario 'Private Officer taking on a case', js: true do
    case_available_for_taking_on
    login_as private_officer
    incoming_cases_page.load

    case_row = incoming_cases_page.case_list.first
    expect(case_row.number).to have_text case_available_for_taking_on.number
    case_row.actions.take_on_case.click
    expect(case_row.actions.success_message).to have_text 'Case taken on'

    case_row.number.click
    expect(cases_show_page.case_history.entries.first)
      .to have_text('Preston Offman Private Office Clearance level added')

    _case_not_for_private_office_open_cases = create :case_being_drafted,
                                                     :flagged,
                                                     :press_office
    open_cases_page.load
    expect(open_cases_page.case_list.first.number)
      .to have_text case_available_for_taking_on.number
    expect(open_cases_page.case_list.count).to eq 1
  end

  scenario 'Press Officer approves a case that requires Private Office approval' do
    login_as pending_press_clearance_case.assigned_press_officer
    cases_show_page.load(id: pending_press_clearance_case.id)

    approve_case_step kase:            pending_press_clearance_case,
                      expected_team:   private_office,
                      expected_status: 'Pending clearance'
    go_to_case_details_step kase:          pending_press_clearance_case,
                            expected_team: private_office
  end

  scenario 'Private Officer approves a case' do
    login_as pending_private_clearance_case.assigned_private_officer

    cases_show_page.load(id: pending_private_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Private Office'

    approve_case_step(
      kase:            pending_private_clearance_case,
      expected_team:   pending_private_clearance_case.responding_team,
      expected_status: 'Ready to send'
    )
    go_to_case_details_step(
      kase:          pending_private_clearance_case,
      expected_team: pending_private_clearance_case.responding_team
    )
  end

  scenario 'Private Officer requests amends to a response' do
    assigned_private_officer = pending_private_clearance_case.approver_assignments.with_teams(BusinessUnit.private_office).first.user
    login_as assigned_private_officer
    cases_show_page.load(id: pending_private_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Private Office'

    request_amends kase:            pending_private_clearance_case,
                   expected_action: 'requesting amends for',
                   expected_team:   dacu_disclosure,
                   expected_status: 'Pending clearance'
    execute_request_amends
    go_to_case_details_step(
      kase:              pending_private_clearance_case,
      find_details_page: false,
      expected_team:     dacu_disclosure,
      expected_history:  ["#{assigned_private_officer.full_name}#{private_office.name}Request amends"]
    )
  end
end
