require 'rails_helper'

feature 'Closing a case' do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario 'editing a case' do
    kase =  create :accepted_case, received_date: 2.days.ago
    open_cases_page.load(timeliness: 'in_time')
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link 'Edit case details'
    expect(cases_edit_page).to be_displayed

    cases_edit_page.date_received_day.set(Date.today.day)
    cases_edit_page.date_received_month.set(Date.today.month)
    cases_edit_page.date_received_year.set(Date.today.year)
    cases_edit_page.subject.set('Aardvarks for sale')
    cases_edit_page.full_request.set('I have heard that prisoners are selling baby aardvarks.  Is that true?')
    cases_edit_page.full_name.set('John Doe')
    cases_edit_page.email.set('john.doe@moj.com')
    cases_edit_page.submit_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.notice.text).to eq 'Case updated'
    expect(cases_show_page.page_heading.heading.text).to eq 'Case subject, Aardvarks for sale'
    expect(cases_show_page.case_details.basic_details.date_received.data.text).to eq Date.today.strftime(Settings.default_date_format)
    expect(cases_show_page.case_details.basic_details.name.data.text).to eq 'John Doe'
    expect(cases_show_page.case_details.basic_details.email.data.text).to eq 'john.doe@moj.com'

  end

end
