require "rails_helper"
require Rails.root.join("db/seeders/case_category_reference_seeder")

feature "Offender SAR Case editing by a manager", :js do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case, :rejected, :third_party, received_date: Date.today.to_date, rejected_reasons: %w[cctv_bwcv change_of_name_certificate court_data_request] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario "user creates a valid case from a rejected case" do
    # TODO: update this throughout rejections work
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    click_on "Create valid case"
    expect(cases_edit_offender_sar_accepted_date_received_page).to be_displayed
    cases_edit_offender_sar_accepted_date_received_page.set_received_date(1.days.ago)
    click_on "Continue"

    then_expect_case_state_to_be_data_to_be_requested
    then_expect_case_date_request_received_to_be_edited

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
end
