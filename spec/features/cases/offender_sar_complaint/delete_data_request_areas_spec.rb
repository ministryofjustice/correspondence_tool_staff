require "rails_helper"

feature "Data Request Areas for an Offender SAR" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }
  given!(:contact) { create(:contact) }
  given!(:data_request_area) { create(:data_request_area, offender_sar_complaint:).decorate }

  background do
    login_as manager
  end
  scenario "delete a data request area which has no sent emails", js: true do
    #TODO
    # update to use emails check
    cases_show_page.load(id: offender_sar_complaint.id)
    click_on "Record data request"
    expect(data_request_area_page).to be_displayed

    click_on "Find an address"
    click_on "Use #{contact.name}"
    data_request_area_page.form.choose_area_request_type("prison")
    click_on "Continue"
    expect(data_request_area_show_page).to be_displayed
    expect(page).to have_content("Data request area successfully recorded")
    expect(page).to have_content("No data requests recorded")

    accept_confirm do
      click_on "Delete", match: :first
    end
  end

  scenario "cannot delete a data request area which has sent emails", js: true do
    #TODO
    # update to use emails check
    data_request_area_show_page.load(case_id: offender_sar_case.id, data_request_area_id: data_request_area.id)    expect(data_request_area_page).to be_displayed

  end
end
