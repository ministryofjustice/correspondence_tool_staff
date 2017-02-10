require 'rails_helper'

feature 'Closing a case' do

  given(:list_view)   { CaseListPage.new        }
  given(:detail_view) { CaseDetailsPage.new     }
  given(:kase)        { create(:responded_case) }

  background do
    kase
    login_as create(:assigner)
  end

  scenario 'A KILO has responded and an assigner closes the case' do
    visit cases_path
    expect(list_view.case_list.last.status.text).to eq 'Waiting to be closed'
    click_link kase.number

    expect(detail_view.sidebar.actions).
      to have_link('Close case', href: close_case_path(kase))
    click_link 'Close case'

    expect(detail_view).to have_content("You've closed this case")
    expect(detail_view.sidebar.status.text).to eq 'Case closed'
    expect(detail_view.sidebar.actions).not_to have_link('Close case')
    expect(detail_view.sidebar.actions.text).to eq 'No actions available'
  end
end
