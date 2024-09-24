require "rails_helper"

feature "Data Request Areas for an Offender SAR" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
  given!(:data_request_area) { create(:data_request_area, offender_sar_case: offender_sar_complaint).decorate }

  background do
    login_as manager
  end

  scenario "delete a data request area which has no sent emails", js: true do
    data_request_area_show_page.load(case_id: offender_sar_complaint.id, data_request_area_id: data_request_area.id)
    expect(data_request_area_show_page).to be_displayed

    accept_confirm do
      click_on "Delete", match: :first
    end
  end

  scenario "cannot delete a data request area which has sent emails", js: true do
    create(:data_request_email, data_request_area:, created_at: "2023-07-07 14:53", email_address: "user@prison.gov.uk")
    data_request_area_show_page.load(case_id: offender_sar_complaint.id, data_request_area_id: data_request_area.id)

    expect(data_request_area_show_page).to be_displayed
    expect(page).not_to have_link("Delete")
  end
end
