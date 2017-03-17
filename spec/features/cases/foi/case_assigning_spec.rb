require 'rails_helper'

feature 'Assigning a case from the detail view' do
  given(:kase)            { create(:case) }
  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  before do
    responding_team
  end

  scenario 'assigning a new case' do
    login_as manager
    visit case_path(kase)
    expect(cases_show_page).to(
      have_link('Assign to a responder', href: new_case_assignment_path(kase))
    )

    click_link 'Assign to a responder'
    expect(page).to have_content('Assign case')

    select responding_team.name, from: 'assignment[team_id]'
    click_button 'Assign case'
    expect(current_path).to eq cases_path
    expect(page).to have_content('Case successfully assigned')

    new_assignment = Assignment.last

    expect(kase.reload).to have_attributes(
                             current_state: 'awaiting_responder',
                             assignments:   [new_assignment]
                           )

    expect(new_assignment).to have_attributes(
                                role:    'responding',
                                team:    responding_team,
                                user_id: nil,
                                case:    kase,
                                state:   'pending'
                              )
  end

  context 'case has been rejected' do
    given(:kase) { create(:assigned_case) }

    before do
      responding_team
      kase.assignments.last.reject(responder, 'No thanks')
    end

    scenario 'assigner reassigns rejected case' do

      login_as manager
      visit case_path(kase)
      expect(cases_show_page).to(
        have_link('Assign to a responder', href: new_case_assignment_path(kase))
      )

      click_link 'Assign to a responder'
      expect(page).to have_content('Assign case')

      select responding_team.name, from: 'assignment[team_id]'
      click_button 'Assign case'
      expect(current_path).to eq cases_path
      expect(page).to have_content('Case successfully assigned')

      new_assignment = Assignment.last

      expect(kase.reload).to have_attributes(
                               current_state: 'awaiting_responder',
                               assignments:   [new_assignment]
                             )

      expect(new_assignment).to have_attributes(
                                  role:    'responding',
                                  team:    responding_team,
                                  user_id: nil,
                                  case:    kase,
                                  state:   'pending'
                                )
    end

  end
end
