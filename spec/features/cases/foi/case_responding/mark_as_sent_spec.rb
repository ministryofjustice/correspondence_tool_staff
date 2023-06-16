require "rails_helper"

feature "Mark response as sent" do
  given(:responder)    { find_or_create(:foi_responder) }
  given(:manager)      { create(:manager) }
  given(:kase)         do
    create(:case_with_response,
           received_date: 10.business_days.ago)
  end
  given(:another_kase) do
    create(:case_with_response,
           received_date: 10.business_days.ago)
  end
  given(:responder_teammate) do
    create :responder, responding_teams: responder.responding_teams
  end

  before do
    kase
    another_kase
    login_as responder
  end

  scenario "the assigned KILO has uploaded a response" do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.fill_in_date_responded(Time.zone.today)

    cases_respond_page.submit_button.click

    expect(cases_show_page)
        .to have_content("The response has been marked as sent.")

    login_as manager
    open_cases_page.load
    expect(open_cases_page.case_numbers).to include kase.number
  end

  scenario "the assigned KILO has uploaded a response but decides not to mark as sent" do
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.back_link.click

    expect(cases_show_page).to be_displayed(kase.id)
  end

  context "as a responder on the same team" do
    background do
      login_as responder_teammate
    end

    scenario "marking the case as sent" do
      cases_show_page.load(id: kase.id)

      cases_show_page.actions.mark_as_sent.click

      cases_respond_page.fill_in_date_responded(Time.zone.today)

      cases_respond_page.submit_button.click

      expect(cases_show_page)
          .to have_content("The response has been marked as sent.")

      login_as manager
      open_cases_page.load
      expect(open_cases_page.case_numbers).to include kase.number
    end
  end
end
