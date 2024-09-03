require "rails_helper"

feature "Log data received for an Offender SAR complaint Data Request" do
  given!(:manager) { find_or_create :branston_user }
  given!(:offender_sar_complaint) { create(:offender_sar_complaint, :data_to_be_requested).decorate }
  given!(:data_request_area) { create(:data_request_area,  offender_sar_case: offender_sar_complaint).decorate }
  given!(:data_request) { create(:data_request, offender_sar_case: offender_sar_complaint, data_request_area:).decorate }

  background do
    login_as manager
  end

  scenario "successfully log initial data received information" do
    data_request_area_show_page.load(case_id: offender_sar_complaint.id, data_request_area_id: data_request_area.id)
    expect(data_request_area_show_page.data_requests.rows.size).to eq 1

    # A brand new DataRequest always has 0 number of pages received
    row = data_request_area_show_page.data_requests.rows[0]
    expect(row.date_requested).to have_text ""
    expect(row.pages).to have_text "0"

    click_link "Edit"
    expect(data_request_edit_page).to be_displayed

    # Pre-fill Number of pages field with current total number of pages
    expect(data_request_edit_page.form.cached_num_pages.value.to_i).to eq 0

    data_request_edit_page.form.cached_num_pages.fill_in(with: 92)

    click_on "Continue"

    expect(data_request_area_show_page).to be_displayed
    expect(data_request_area_show_page).to have_text "Data request updated"
    expect(data_request_area_show_page.data_requests.rows.size).to eq 1 # Unchanged num DataRequest

    row = data_request_area_show_page.data_requests.rows[0]
    expect(row.pages).to have_text "92"


    # Note pre-filled fields when making further update to the same Data Request
    click_link "Edit"
    expect(data_request_edit_page).to be_displayed
    expect(data_request_edit_page.form.cached_num_pages.value).to eq "92"
  end

  context "when multiple data requests are present and have pages logged" do
    given!(:data_request) { create(:data_request, offender_sar_case: offender_sar_complaint, data_request_area:, cached_num_pages: 32) }
    given!(:second_data_request) { create(:data_request, offender_sar_case: offender_sar_complaint, data_request_area:, cached_num_pages: 32) }

    scenario "the total row displays with the correct total pages" do
      data_request_area_show_page.load(case_id: offender_sar_complaint.id, data_request_area_id: data_request_area.id)
      expect(data_request_area_show_page).to be_displayed
      expect(data_request_area_show_page.data_requests.rows.size).to eq 3 # Unchanged num DataRequest
      last_row = data_request_area_show_page.data_requests.rows.last
      expect(last_row.has_selector?(".total-label")).to eq true
      expect(last_row.total_label).to have_text "Total"
      expect(last_row.has_selector?(".total-value")).to eq true
      expect(last_row.total_value).to have_text "64"
    end
  end

  context "when marking a data request complete" do
    scenario "the row displays with the correct status", :js do
      data_request_area_show_page.load(case_id: offender_sar_complaint.id, data_request_area_id: data_request_area.id)
      expect(data_request_area_show_page).to be_displayed
      expect(data_request_area_show_page.data_requests.rows.size).to eq 1
      click_link "Edit"

      expect(data_request_edit_page).to be_displayed
      data_request_edit_page.form.mark_complete
      click_on "Continue"

      expect(data_request_area_show_page).to be_displayed
      row = data_request_area_show_page.data_requests.rows[0]
      expect(row.status).to have_text "Completed"
    end
  end
end
