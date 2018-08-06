require 'rails_helper'

feature 'editing an ICO case' do
  given(:manager) { create :disclosure_bmt_user }

  background do
    login_as manager
  end

  scenario 'changing details' do
    kase = create :ico_foi_case

    cases_show_page.load(id: kase.id)
    expect(cases_show_page).to be_displayed(id: kase.id)
    click_link 'Edit case details'
    expect(cases_edit_page).to be_displayed

  #   cases_edit_page.foi_detail.date_received_day.set(Date.today.day)
  #   cases_edit_page.foi_detail.date_received_month.set(Date.today.month)
  #   cases_edit_page.foi_detail.date_received_year.set(Date.today.year)
  #   cases_edit_page.foi_detail.subject.set('Aardvarks for sale')
  #   cases_edit_page.foi_detail.full_request.set('I have heard that prisoners are selling baby aardvarks.  Is that true?')
  #   cases_edit_page.foi_detail.full_name.set('John Doe')
  #   cases_edit_page.foi_detail.email.set('john.doe@moj.com')
  #   cases_edit_page.submit_button.click

  #   expect(cases_show_page).to be_displayed
  #   expect(cases_show_page.notice.text).to eq 'Case updated'
  #   expect(cases_show_page.page_heading.heading.text).to eq 'Case subject, Aardvarks for sale'
  #   expect(cases_show_page.case_details.foi_basic_details.date_received.data.text).to eq Date.today.strftime(Settings.default_date_format)
  #   expect(cases_show_page.case_details.foi_basic_details.name.data.text).to eq 'John Doe'
  #   expect(cases_show_page.case_details.foi_basic_details.email.data.text).to eq 'john.doe@moj.com'

  end

end
