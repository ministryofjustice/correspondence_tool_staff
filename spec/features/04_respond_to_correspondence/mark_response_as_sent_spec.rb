require 'rails_helper'

feature 'Mark response as sent' do

  given(:drafter)        { create(:drafter)                              }
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
    visit case_path(kase)
    expect(detail_page.sidebar.actions).to have_link('Mark response as sent',
                                  href: respond_case_path(kase))
    click_link 'Mark response as sent'

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
    expect(response_page).to have_link('Mark response as sent',
                                  href: confirm_respond_case_path(kase))
    click_link 'Mark response as sent'

    expect(kase.current_state).to eq 'responded'
    expect(current_path).to eq '/cases'
    expect(case_list_page.case_list.count).to eq 1

    remaining_case_row = case_list_page.case_list.first

    expect(remaining_case_row.number).
      not_to have_link(kase.number,
        href: Rails.root.join("/cases/#{kase.id}"))
    expect(remaining_case_row.number).
      to have_link(another_kase.number,
        href: Rails.root.join("/cases/#{another_kase.id}"))
    expect(case_list_page).to have_content(
      'Response confirmed. The case is now with DACU.'
    )
  end

end
