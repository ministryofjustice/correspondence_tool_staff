# This would be better placed in e2e journey spec

require 'rails_helper'

feature 'creating and adding message to an overturned SAR' do
  include Features::Interactions

  given(:responder)             { create :responder }
  given!(:responding_team)      { create :responding_team, responders: [responder] }
  given!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given(:manager)               { create :disclosure_bmt_user }
  given(:managing_team)         { create :managing_team, managers: [manager] }

  background do
    login_as manager
    cases_page.load
  end

  scenario "add message to case" do
    ico_case = create(:ico_sar_case)

    cases_show_page.load(id: ico_case.id)
    expect(cases_show_page).to be_displayed(id: ico_case.id)
    cases_new_overturned_ico_page.load(id: ico_case.id)

    expect(cases_new_overturned_ico_page).to be_displayed
    expect(cases_new_overturned_ico_page).to have_sar_form
    expect(cases_new_overturned_ico_page).to have_text(ico_case.number)

    form = cases_new_overturned_ico_page.sar_form
    date_received = Date.today
    form.date_received_day.set(date_received.day)
    form.date_received_month.set(date_received.month)
    form.date_received_year.set(date_received.year)

    final_deadline = 10.business_days.from_now
    form.final_deadline_day.set(final_deadline.day)
    form.final_deadline_month.set(final_deadline.month)
    form.final_deadline_year.set(final_deadline.year)

    expect(form.reply_method.send_by_email).to be_checked
    expect(form.reply_method.email.value).to eq ico_case.original_case.email

    click_button 'Create case'

    kase = Case::OverturnedICO::SAR.last
    cases_show_page.load(id: kase.id)

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: true


  end
end
