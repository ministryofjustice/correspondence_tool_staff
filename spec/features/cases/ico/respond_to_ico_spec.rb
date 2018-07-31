require 'rails_helper'

feature 'Mark response as sent' do
  given(:approver)     { create(:disclosure_specialist) }
  given(:manager)      { create(:manager) }
  given(:kase)         { create(:approved_ico_foi_case,
                                approver: approver,
                                received_date: 10.business_days.ago) }
  before do
    kase
    login_as approver
  end

  scenario 'the assigned KILO has uploaded a response' do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.fill_in_date_responded(Date.today)

    cases_respond_page.submit_button.click

    expect(cases_show_page).
        to have_content('The response has been marked as sent.')

    expect(cases_show_page.case_details.response_details.date_responded.data.text)
      .to eq 0.business_days.ago.strftime(Settings.default_date_format)

    login_as manager
    open_cases_page.load
    # expect(open_cases_page.case_numbers).to include kase.number
  end

  scenario 'the assigned KILO has uploaded a response but decides not to mark as sent' do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.back_link.click

    expect(cases_show_page).to be_displayed(kase.id)

  end

end
