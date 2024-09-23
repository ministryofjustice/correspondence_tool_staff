require "rails_helper"
require Rails.root.join("db/seeders/case_category_reference_seeder")

feature "Offender SAR Case editing by a manager", :js do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case, :rejected, :third_party, received_date: Time.zone.today.to_date, rejected_reasons: %w[cctv_bwcv change_of_name_certificate court_data_request] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario "user creates a valid case from a rejected case" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    click_on "Create valid case"
    expect(cases_edit_offender_sar_accepted_date_received_page).to be_displayed
    cases_edit_offender_sar_accepted_date_received_page.set_received_date(1.day.ago)
    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case updated"
    expect(cases_show_page.case_status).to have_content "Data to be requested"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history).to have_content "Valid case created"

    expect(cases_show_page).to have_content "CCTV / BWCV request"
    expect(cases_show_page).to have_content "Change of name certificate"
    expect(cases_show_page).to have_content "Court data request"

    expect(cases_show_page).to have_content(I18n.l(offender_sar_case.received_date - 1, format: :default))
  end

  scenario "user can click the 'change' link and edit the rejected reasons" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)
    cases_show_page.offender_sar_reason_rejected.change_link.click

    expect(cases_edit_offender_sar_reason_rejected_page).to be_displayed
    cases_edit_offender_sar_reason_rejected_page.choose_rejected_reason("telephone_transcripts")
    click_on "Continue"

    expect(cases_show_page).to have_content "Case updated"
    expect(cases_show_page).to have_content "Telephone transcripts"
  end

  scenario "user cannot see the 'change' link after validating a rejected case" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    click_on "Create valid case"
    expect(cases_edit_offender_sar_accepted_date_received_page).to be_displayed
    cases_edit_offender_sar_accepted_date_received_page.set_received_date(1.day.ago)
    click_on "Continue"

    expect(cases_show_page.offender_sar_reason_rejected).not_to have_link "Change"
  end

  scenario "case remains rejected after editing subject details page" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    cases_show_page.offender_sar_subject_details.change_link.click
    cases_edit_offender_sar_subject_details_page.edit_name "Bob Hope"
    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case updated"
    expect(cases_show_page.case_status).to have_content "Rejected"
  end

  scenario "external_deadline remains 90 days for a rejected case after editing the received_date" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    cases_show_page.offender_sar_date_received.change_link.click
    expect(cases_edit_offender_sar_date_received_page).to be_displayed
    cases_edit_offender_sar_date_received_page.edit_received_date(90.days.ago)
    formatted_date = Time.zone.today.to_date.strftime("%d %b %Y")

    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Final deadline"
    expect(cases_show_page).to have_content formatted_date
  end

  scenario "rejected to closed case remains closed after editing subject details page" do
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    click_on "Close case"
    cases_close_page.fill_in_date_responded(offender_sar_case.received_date)
    click_on "Continue"
    expect(cases_show_page).to have_content "You've closed this case"

    cases_show_page.offender_sar_subject_details.change_link.click
    cases_edit_offender_sar_subject_details_page.edit_name "Bob Hope"
    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Case updated"
    expect(cases_show_page.case_status).to have_content "Closed"
  end
end
