require "rails_helper"

feature "Cover page for an Offender SAR" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case, :waiting_for_data, received_date: 1.working.day.ago).decorate }

  background do
    5.times do
      create(:data_request, offender_sar_case:)
    end
    login_as manager
  end

  scenario "for a case with 5 data requests" do
    cases_show_page.load(id: offender_sar_case.id)
    click_on "Preview cover page"

    expect(cases_cover_page).to be_displayed
    data_requests = cases_cover_page.data_requests.rows
    expect(data_requests.size).to eq 5
    expect(cases_cover_page.final_deadline).to have_text "Final deadline: #{offender_sar_case.external_deadline}"
  end
end
