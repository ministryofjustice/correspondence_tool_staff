require "rails_helper"

feature "Data Request Areas for an Offender SAR Complaint" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }

  background do
    login_as manager
  end

  scenario "successfully add a new data request area", js: true do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"

    click_on "Record data request"
    expect(data_request_area_page).to be_displayed

    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"
    expect(data_request_area_show_page).to be_displayed
    expect(page).to have_content("Data request area successfully recorded")
    expect(page).to have_content("No data requests recorded")
  end

  scenario "no data entry fails", js: true do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"

    click_on "Record data request"
    expect(data_request_area_page).to be_displayed

    click_on "Continue"
    expect(data_request_area_page).to be_displayed
    expect(data_request_area_page).to have_text "Select where the data you are requesting is from"
  end

  scenario "delete a data request area which has no data requests", js: true do
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Requires data"
    click_on "Record data request"
    expect(data_request_area_page).to be_displayed

    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"
    expect(data_request_area_show_page).to be_displayed
    expect(page).to have_content("Data request area successfully recorded")
    expect(page).to have_content("No data requests recorded")

    accept_confirm do
      click_on "Delete", match: :first
    end
  end
end
