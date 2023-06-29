require "rails_helper"

feature "Sent To SSCL date" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case, :ready_for_vetting, received_date: 1.business_day.ago).decorate }
  given(:sent_to_sscl_offender_sar_case) { create(:offender_sar_case, :ready_for_vetting, received_date: 1.business_day.ago, sent_to_sscl_at: 1.week.ago).decorate }

  background do
    login_as manager
  end

  scenario "Add Sent To SSCL date" do
    cases_show_page.load(id: offender_sar_case.id)
    click_on "Sent to SSCL"

    expect(cases_edit_offender_sar_sent_to_sscl_page).to be_displayed
    cases_edit_offender_sar_sent_to_sscl_page.edit_sent_to_sscl_at 1.week.ago.to_date
    cases_edit_offender_sar_sent_to_sscl_page.continue_button.click

    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    expect(cases_show_page).to have_content I18n.l(1.week.ago.to_date, format: :default)
    expect(cases_show_page).to have_content "Case updated"
    expect(cases_show_page).to have_content "Sent to SSCL for Vetting"
  end

  scenario "Edit Sent To SSCL date" do
    cases_show_page.load(id: sent_to_sscl_offender_sar_case.id)
    cases_show_page.offender_sar_sent_to_sscl.change_link.click

    expect(cases_edit_offender_sar_sent_to_sscl_page).to be_displayed
    cases_edit_offender_sar_sent_to_sscl_page.edit_sent_to_sscl_at 2.weeks.ago.to_date
    cases_edit_offender_sar_sent_to_sscl_page.continue_button.click

    expect(cases_show_page).to be_displayed(id: sent_to_sscl_offender_sar_case.id)
    expect(cases_show_page).to have_content I18n.l(2.weeks.ago.to_date, format: :default)
    expect(cases_show_page).to have_content "Case updated"
  end

  scenario "Remove Sent To SSCL date", js: true do
    cases_show_page.load(id: sent_to_sscl_offender_sar_case.id)
    cases_show_page.offender_sar_sent_to_sscl.change_link.click

    expect(cases_edit_offender_sar_sent_to_sscl_page).to be_displayed
    cases_edit_offender_sar_sent_to_sscl_page.remove_button.click
    cases_edit_offender_sar_sent_to_sscl_page.remove_reason.set "ipsum lorem"
    cases_edit_offender_sar_sent_to_sscl_page.continue_button.click

    expect(cases_show_page).to be_displayed(id: sent_to_sscl_offender_sar_case.id)
    expect(cases_show_page).to have_content "SSCL date sent removed"
    expect(cases_show_page).to have_content "(Reason: ipsum lorem)"
  end
end
