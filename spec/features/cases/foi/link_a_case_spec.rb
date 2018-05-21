require 'rails_helper'

feature 'Linking a case' do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario 'editing a case in drafting state' do
    kase_1 =  create :accepted_case
    kase_2 =  create :accepted_case
    open_cases_page.load
    click_link kase_1.number
    expect(cases_show_page).to be_displayed

    cases_show_page.link_case.action_link.click
    expect(cases_new_case_link_page).to be_displayed(id: kase_1.id)

    cases_new_case_link_page.create_a_new_case_link(kase_2.number)
    expect(cases_show_page).to be_displayed(id: kase_1.id)
    expect(cases_show_page.notice.text).to eq "Case #{kase_2.number} has been linked to this case"

    cases_show_page.link_case.linked_records.first.link.click
    expect(cases_show_page).to be_displayed(id: kase_2.id)
  end

  scenario 'editing a case in unassigned state' do
    kase_1 =  create :case
    kase_2 =  create :case
    open_cases_page.load
    click_link kase_1.number
    expect(cases_show_page).to be_displayed

    cases_show_page.link_case.action_link.click
    expect(cases_new_case_link_page).to be_displayed(id: kase_1.id)

    cases_new_case_link_page.create_a_new_case_link(kase_2.number)
    expect(cases_show_page).to be_displayed(id: kase_1.id)
    expect(cases_show_page.notice.text).to eq "Case #{kase_2.number} has been linked to this case"

    cases_show_page.link_case.linked_records.first.link.click
    expect(cases_show_page).to be_displayed(id: kase_2.id)
  end


end
