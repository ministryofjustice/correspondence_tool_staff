require 'rails_helper'

feature 'Closing a case' do
  given(:kase)        { create(:responded_case) }

  background do
    kase
    login_as create(:assigner)
  end

  scenario 'A KILO has responded and an assigner closes the case' do
    visit cases_path
    expect(cases_page.case_list.last.status.text).to eq 'Waiting to be closed'
    click_link kase.number

    expect(cases_show_page.sidebar.actions).
      to have_link('Close case', href: close_case_path(kase))
    click_link 'Close case'

    expect(cases_show_page).to have_content("You've closed this case")
    expect(cases_show_page.sidebar.status.text).to eq 'Case closed'
    expect(cases_show_page.sidebar.actions).not_to have_link('Close case')
    expect(cases_show_page.sidebar.actions.text).to eq 'No actions available'
  end
end
