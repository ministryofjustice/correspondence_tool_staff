require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given!(:dacu_disclosure)             { find_or_create :team_dacu_disclosure }
  given(:disclosure_specialist)        { create :disclosure_specialist }
  given(:other_disclosure_specialist)  { create :disclosure_specialist }
  given!(:press_office)                { find_or_create :team_press_office }
  given!(:press_officer)               { create :press_officer,
                                                full_name: 'Preston Offman' }
  given!(:private_office)              { find_or_create :team_private_office }
  given!(:private_officer)             { create :private_officer }
  given(:case_available_for_taking_on) { create :case_being_drafted,
                                                created_at: 1.business_day.ago }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end
  given(:pending_press_clearance_case) { create :pending_press_clearance_case,
                                                press_officer: press_officer }

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
      .to have_text('Preston Offman Take on for approval')
    expect(cases_show_page.case_history.entries[1])
      .to have_text("#{private_officer.full_name} Flag for clearance")

    _case_not_for_private_office_open_cases = create :case_being_drafted,
                                                     :flagged_accepted,
                                                     :press_office
    open_cases_page.load
    expect(open_cases_page.case_list.first.number)
      .to have_text case_available_for_taking_on.number
    expect(open_cases_page.case_list.count).to eq 1
  end
end
