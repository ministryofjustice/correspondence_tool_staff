require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given(:disclosure_specialist) { create :disclosure_specialist }
  given(:press_officer)         { create :press_officer }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end

  scenario 'Disclosure Specialist approves a case that requires Press Office approval' do
    login_as disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)
    cases_show_page.actions.clear_case.click

    # expect(approve_response_page)
    #   .to have_text('It will then be with Press Office')
    # expect(approve_response_page)
    #   .to have_text('with the status Pending Clearance')
    # TODO: expect the link to go to an escalation case_path, not
    #       approve_response_case_path
  end
end
