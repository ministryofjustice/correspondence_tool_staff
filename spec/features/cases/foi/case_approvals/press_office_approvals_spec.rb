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

    go_to_case_details_step(
      page: incoming_cases_page,
      kase: case_available_for_taking_on,
      expected_history: [
        'Primrose Offord Press Office Clearance level added'
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

  scenario 'Disclosure Specialist approves a case that requires Press Office approval', js: true do
    login_as disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)

    approve_case_step kase: pending_dacu_clearance_case,
                      expected_team: press_office,
                      expected_status: 'Pending clearance'

    go_to_case_details_step kase: pending_dacu_clearance_case,
                            expected_team: press_office
  end

  scenario 'Press Officer approves a case' do
    login_as press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'

    approve_case_step kase: pending_press_clearance_case,
                      expected_team: pending_press_clearance_case.responding_team,
                      expected_status: 'Ready to send'
    go_to_case_details_step(
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
    execute_request_amends
    go_to_case_details_step(
      kase: pending_press_clearance_case,
      find_details_page: false,
      expected_team: dacu_disclosure,
      expected_history: [
        "#{press_officer.full_name}#{press_office.name}Request amends"
      ]
    )
  end
end
