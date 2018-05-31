require 'rails_helper'

feature 'Editing a SAR case' do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario 'editing a case' do
    kase =  create :accepted_sar, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link 'Edit case details'
    expect(cases_edit_page).to be_displayed

    detail = cases_edit_page.sar_detail
    detail.subject_name.set('Stepriponikas Bonstart')

    cases_edit_page.sar_detail.date_received_day.set(Date.today.day)
    cases_edit_page.sar_detail.date_received_month.set(Date.today.month)
    cases_edit_page.sar_detail.date_received_year.set(Date.today.year)

    cases_edit_page.sar_detail.case_summary.set('Aardvarks for sale')
    cases_edit_page.sar_detail.full_request.set('I have heard that prisoners are selling baby aardvarks.  Is that true?')
    cases_edit_page.submit_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.notice.text).to eq 'Case updated'

    expect(cases_show_page.page_heading.heading.text).to eq 'Case subject, Aardvarks for sale'
    expect(cases_show_page.case_details.sar_basic_details.data_subject.data.text).to eq 'Stepriponikas Bonstart'
    expect(cases_show_page.case_details.sar_basic_details.date_received.data.text).to eq Date.today.strftime(Settings.default_date_format)
  end

end
