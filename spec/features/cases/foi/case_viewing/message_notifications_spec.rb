require "rails_helper"

feature "case message notifications" do
  given(:kase)          { create :accepted_case, :flagged_accepted, :dacu_disclosure }
  given(:responder)     { kase.responder }
  given(:managing_team) { kase.managing_team }
  given(:manager)       { managing_team.managers.first }

  background do
    kase.state_machine.add_message_to_case!(
      acting_user: manager,
      acting_team: managing_team,
      message: "Notify Me!",
    )
    login_as responder
  end

  scenario "user views a case with a message notification" do
    open_cases_page.load
    expect(open_cases_page.case_list.first.message_notification)
      .to be_visible
    open_cases_page.case_list.first.number.find("a").click
    expect(cases_show_page).to be_displayed(id: kase.id)
    open_cases_page.load
    expect(open_cases_page.case_list.first).not_to have_message_notification

    login_as manager
    cases_show_page.load(id: kase.id)
    cases_show_page.new_message.input.set "A new message"
    cases_show_page.new_message.add_button.click

    login_as responder
    open_cases_page.load
    expect(open_cases_page.case_list.first).to have_message_notification
  end
end
