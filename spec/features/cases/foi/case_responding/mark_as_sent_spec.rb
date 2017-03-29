require 'rails_helper'

feature 'Mark response as sent' do
  given(:drafter)        { create(:drafter)                              }
  given(:assigner)       { create(:assigner)                             }
  given(:kase)           { create(:case_with_response, drafter: drafter) }
  given(:another_kase)   { create(:case_with_response, drafter: drafter) }

  before do
    kase
    another_kase
    login_as drafter
  end

  scenario 'the assigned KILO has uploaded a response' do
    cases_show_page.load(id: kase.id)

    expect(cases_show_page.sidebar.actions).to have_upload_response
    expect(cases_show_page.sidebar.actions).to have_mark_as_sent
    cases_show_page.sidebar.actions.mark_as_sent.click

    expect(current_path).to eq respond_case_path(kase.id)
    expect(cases_respond_page).to have_reminders
    expect(cases_respond_page.reminders.text).to eq(
"Check the response has been: cleared by the Deputy Director uploaded \
with any supporting documents sent to the requester"
      )
    expect(cases_respond_page).to have_alert
    expect(cases_respond_page.alert.text).to eq(
"Important After this step you'll no longer be able to upload an updated \
version and DACU will be notified to review the case."
      )
    expect(cases_respond_page).to have_mark_as_sent_button
    cases_respond_page.mark_as_sent_button.click

    expect(current_path).to eq '/cases'
    expect(cases_page.case_numbers).not_to include kase.number
    expect(cases_page).
      to have_content('Response confirmed. The case is now with DACU.')
    expect(kase.current_state).to eq 'responded'

    login_as assigner
    cases_page.load
    expect(cases_page.case_numbers).to include kase.number
  end

  scenario 'the assigned KILO has uploaded a response but decides not to mark as sent' do
    cases_show_page.load(id: kase.id)

    cases_show_page.sidebar.actions.mark_as_sent.click

    expect(cases_respond_page).to be_displayed
    expect(cases_respond_page).to have_reminders
    expect(cases_respond_page.reminders.text).to eq(
"Check the response has been: cleared by the Deputy Director uploaded \
with any supporting documents sent to the requester"
    )
    expect(cases_respond_page).to have_alert
    expect(cases_respond_page.alert.text).to eq(
"Important After this step you'll no longer be able to upload an updated \
version and DACU will be notified to review the case."
    )
    expect(cases_respond_page).to have_mark_as_sent_button

    expect(cases_respond_page).to have_back_link

    cases_respond_page.back_link.click

    expect(current_path).to eq case_path(kase.id)

  end

end
