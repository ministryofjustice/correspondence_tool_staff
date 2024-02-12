require "rails_helper"
require Rails.root.join("db/seeders/case_category_reference_seeder")

feature "Offender SAR Case editing by a manager", :js do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_case) { create :offender_sar_case, :rejected, :third_party, received_date: 2.weeks.ago.to_date, rejected_reasons: %w[cctv_bwcv change_of_name_certificate court_data_request] }

  background do
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_case.id)
  end

  scenario "user updates rejected reasons but SAR cannot be accepted" do
    #todo complete this after cdpt-1036 - button is required
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    # button click part goes here
    # click_on "Information received"
    expect(cases_edit_offender_sar_information_received_page).to be_displayed
  end

  scenario "SAR can be accepted" do
    #todo complete this after cdpt-1036 - button is required
    expect(cases_show_page).to be_displayed(id: offender_sar_case.id)

    # button click part goes here
    # click_on "Information received"
    expect(cases_edit_offender_sar_information_received_page).to be_displayed
  end
end
