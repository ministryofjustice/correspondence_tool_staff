require 'rails_helper'

feature 'Mark response as sent' do
  given(:responder)    { create(:responder) }
  given(:manager)      { create(:manager) }
  given(:kase)         { create(:case_with_response,
                                responder: responder,
                                received_date: 10.business_days.ago) }
  given(:another_kase) { create(:case_with_response,
                                responder: responder,
                                received_date: 10.business_days.ago) }
  given(:responder_teammate) do
    create :responder,
           responding_teams: responder.responding_teams
  end

  before do
    kase
    another_kase
    login_as responder
  end

  scenario 'the assigned KILO has uploaded a response' do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.mark_as_sent_button.click

    expect(cases_show_page).
        to have_content('The response has been marked as sent.')

    login_as manager
    open_cases_page.load(timeliness: 'in_time')
    expect(open_cases_page.case_numbers).to include kase.number
  end

  scenario 'the assigned KILO has uploaded a response but decides not to mark as sent' do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.back_link.click

    expect(cases_show_page).to be_displayed(kase.id)

  end

  context 'as a responder on the same team' do
    background do
      login_as responder_teammate
    end

    scenario 'marking the case as sent' do
      cases_show_page.load(id: kase.id)

      cases_show_page.actions.mark_as_sent.click

      expect(cases_respond_page).to be_displayed(kase.id)
    end
  end
end
