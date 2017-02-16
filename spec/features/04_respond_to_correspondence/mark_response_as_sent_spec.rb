require 'rails_helper'

feature 'Mark response as sent' do

  given(:drafter)        { create(:drafter)                              }
  given(:assigner)       { create(:assigner)                             }
  given(:kase)           { create(:case_with_response, drafter: drafter) }
  given(:another_kase)   { create(:case_with_response, drafter: drafter) }
  given(:detail_page)    { CaseDetailsPage.new                           }
  given(:response_page)  { CaseResponsePage.new                          }
  given(:case_list_page) { CaseListPage.new                              }

  before do
    kase
    another_kase
    login_as drafter
  end

  scenario 'the assigned KILO has uploaded a response' do
    detail_page.load(id: kase.id)

    expect(detail_page.sidebar).to have_mark_as_sent_button
    detail_page.sidebar.mark_as_sent_button.click

    expect(current_path).to eq respond_case_path(kase.id)
    expect(response_page).to have_reminders
    expect(response_page.reminders.text).to eq(
"Check the response has been: cleared by the Deputy Director uploaded \
with any supporting documents sent to the requester"
      )
    expect(response_page).to have_alert
    expect(response_page.alert.text).to eq(
"Important After this step you'll no longer be able to upload an updated \
version and DACU will be notified to review the case."
      )
    expect(response_page).to have_mark_as_sent_button
    response_page.mark_as_sent_button.click

    expect(current_path).to eq '/cases'
    expect(case_list_page.case_numbers).not_to include kase.number
    expect(case_list_page).
      to have_content('Response confirmed. The case is now with DACU.')
    expect(kase.current_state).to eq 'responded'

    login_as assigner
    case_list_page.load
    expect(case_list_page.case_numbers).to include kase.number
  end

end
