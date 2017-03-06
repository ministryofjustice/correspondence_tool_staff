require 'rails_helper'

feature 'Assigning a case from the detail view' do
  given(:kase)        { create(:case)                       }
  given(:drafter)     { create(:user, roles: ['drafter'])   }
  given(:assigner)    { create(:user, roles: ['assigner'])  }
  given(:approver)    { create(:user, roles: ['approver'])  }

  before do
    drafter
  end

  scenario 'assigning a new case' do
    login_as assigner
    visit case_path(kase)
    expect(cases_show_page).to(
      have_link('Assign to a responder', href: new_case_assignment_path(kase))
    )

    click_link 'Assign to a responder'
    expect(page).to have_content('Assign case')

    select drafter.full_name, from: 'assignment[assignee_id]'
    click_button 'Assign case'
    expect(current_path).to eq cases_path
    expect(page).to have_content('Case successfully assigned')

    new_assignment = Assignment.last

    expect(kase.reload).to have_attributes(
                             current_state:       'awaiting_responder',
                             assignments:         [new_assignment]
                           )

    expect(new_assignment).to have_attributes(
                                assignment_type: 'drafter',
                                assignee:        drafter,
                                assigner:        assigner,
                                case:            kase,
                                state:           'pending'
                              )
  end

  context 'case has been rejected' do
    given(:kase) { create(:assigned_case) }

    before do
      drafter
      kase.assignments.last.reject('No thanks')
    end

    scenario 'assigner reassigns rejected case' do

      login_as assigner
      visit case_path(kase)
      expect(cases_show_page).to(
        have_link('Assign to a responder', href: new_case_assignment_path(kase))
      )

      click_link 'Assign to a responder'
      expect(page).to have_content('Assign case')

      select drafter.full_name, from: 'assignment[assignee_id]'
      click_button 'Assign case'
      expect(current_path).to eq cases_path
      expect(page).to have_content('Case successfully assigned')

      new_assignment = Assignment.last

      expect(kase.reload).to have_attributes(
                               current_state:       'awaiting_responder',
                               assignments:         [new_assignment]
                             )

      expect(new_assignment).to have_attributes(
                                  assignment_type: 'drafter',
                                  assignee:        drafter,
                                  assigner:        assigner,
                                  case:            kase,
                                  state:           'pending'
                                )
    end

    scenario 'users without the assigner role cannot cannot reassign' do

      login_as drafter
      visit case_path(kase)
      expect(cases_show_page).to_not(
        have_link('Assign to a responder', href: new_case_assignment_path(kase))
      )

      login_as approver
      visit case_path(kase)
      expect(cases_show_page).to_not(
        have_link('Assign to a responder', href: new_case_assignment_path(kase))
      )
    end
  end
end
