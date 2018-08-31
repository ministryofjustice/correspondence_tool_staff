require 'rails_helper'

feature 'Assigning a case from the detail view' do
  given(:kase)            { create(:overturned_ico_sar) }
  given(:responding_team) { create(:responding_team) }
  given(:responder)       { responding_team.users.first }
  given(:manager)         { create(:disclosure_bmt_user)  }
  given(:assignment)      { kase.responder_assignment }

  before do
    responding_team
    login_as manager
  end

  scenario 'assigning a new case' do
    visit case_path(kase)
    expect(cases_show_page).to(
      have_link('Assign to a responder', href: new_case_assignment_path(kase))
    )
    click_link 'Assign to a responder'
    assign_case_step business_unit: responder.responding_teams.first,
                     expected_flash_msg: 'Case successfully assigned'

    newest_assignment = Assignment.last

    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.assignments).to include newest_assignment

    expect(newest_assignment).to have_attributes(
                                   role:    'responding',
                                   team:    responding_team,
                                   user_id: nil,
                                   case:    kase,
                                   state:   'pending'
                                 )
  end
end
