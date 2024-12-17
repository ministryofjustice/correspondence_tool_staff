require "rails_helper"

feature "Log data received for an Offender SAR Data Request" do
  given!(:manager) { find_or_create :branston_user }
  given!(:offender_sar_case) { create(:offender_sar_case) }
  given!(:data_request) { create(:data_request, offender_sar_case:) }

  background do
    login_as manager
  end

  scenario "successfully log initial data received information" do
    cases_show_page.load(id: offender_sar_case.id)
    expect(cases_show_page.data_requests.rows.size).to eq 1

    # A brand new DataRequest always has 0 number of pages received
    row = cases_show_page.data_requests.rows.first
    expect(row.date_requested).to have_text ""
    expect(row.pages).to have_text "0"

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row.has_selector?(".total-label")).to eq false
    expect(last_row.total_label).not_to have_text "Total"
    expect(last_row.has_selector?(".total-value")).to eq false
    expect(last_row.total_value).not_to have_text "0"

    click_link "Edit"
    expect(data_request_edit_page).to be_displayed

    # Pre-fill Number of pages field with current total number of pages
    expect(data_request_edit_page.form.cached_num_pages.value.to_i).to eq 0

    data_request_edit_page.form.cached_num_pages.fill_in(with: 92)

    click_on "Continue"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_text "Data request updated"
    expect(cases_show_page.data_requests.rows.size).to eq 1 # Unchanged num DataRequest

    row = cases_show_page.data_requests.rows.first
    expect(row.pages).to have_text "92"

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row.has_selector?(".total-label")).to eq false
    expect(last_row.total_label).not_to have_text "Total"
    expect(last_row.has_selector?(".total-value")).to eq false
    expect(last_row.total_value).not_to have_text "0"

    # Note pre-filled fields when making further update to the same Data Request
    click_link "Edit"
    expect(data_request_edit_page).to be_displayed
    expect(data_request_edit_page.form.cached_num_pages.value).to eq "92"
  end

  context "when multiple data requests are present and have pages logged" do
    given!(:data_request) { create(:data_request, offender_sar_case:, cached_num_pages: 32) }
    given!(:second_data_request) { create(:data_request, offender_sar_case:, cached_num_pages: 32) }
    scenario "the total row displays with the correct total pages" do
      cases_show_page.load(id: offender_sar_case.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.data_requests.rows.size).to eq 3 # Unchanged num DataRequest
      last_row = cases_show_page.data_requests.rows.last
      expect(last_row.has_selector?(".total-label")).to eq true
      expect(last_row.total_label).to have_text "Total"
      expect(last_row.has_selector?(".total-value")).to eq true
      expect(last_row.total_value).to have_text "64"
    end
  end

  context "when marking a data request complete" do
    scenario "the row displays with the correct status", :js do
      cases_show_page.load(id: offender_sar_case.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.data_requests.rows.size).to eq 1
      click_link "Edit"
      expect(data_request_edit_page).to be_displayed
      data_request_edit_page.form.mark_complete
      data_request_edit_page.form.set_date_received(Time.zone.today)
      click_on "Continue"
      expect(cases_show_page).to be_displayed
      row = cases_show_page.data_requests.rows[0]

      expect(row.status).to have_text "Completed"
      expect(row.date_received).to have_text Time.zone.today.strftime(Settings.default_date_format)
    end
  end
end
