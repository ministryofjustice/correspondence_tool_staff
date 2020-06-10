require 'rails_helper'

feature 'Log data received for an Offender SAR Data Request' do
  given!(:manager) { find_or_create :branston_user }
  given!(:offender_sar_case) { create(:offender_sar_case) }
  given!(:data_request) { create(:data_request, offender_sar_case: offender_sar_case) }

  background do
    login_as manager
  end

  scenario 'successfully log initial data received information' do
    cases_show_page.load(id: offender_sar_case.id)
    expect(cases_show_page.data_requests.rows.size).to eq 1

    # A brand new DataRequest always has 0 number of pages received
    row = cases_show_page.data_requests.rows.first
    expect(row.date_received).to have_text ''
    expect(row.pages).to have_text '0'

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row).not_to have_selector '.total-label'
    expect(last_row.total_label).not_to have_text 'Total'
    expect(last_row).not_to have_selector '.total-value'
    expect(last_row.total_value).not_to have_text '0'

    click_link 'Update page count'
    expect(data_request_edit_page).to be_displayed

    # Pre-fill Number of pages field with current total number of pages
    expect(data_request_edit_page.form.num_pages.value.to_i).to eq 0

    data_request_edit_page.form.date_received_dd.fill_in(with: 2)
    data_request_edit_page.form.date_received_mm.fill_in(with: 3)
    data_request_edit_page.form.date_received_yyyy.fill_in(with: 2012)
    data_request_edit_page.form.num_pages.fill_in(with: 92)

    click_on 'Update data received'

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_text 'Data request updated'
    expect(cases_show_page.data_requests.rows.size).to eq 1 # Unchanged num DataRequest

    row = cases_show_page.data_requests.rows.first
    expect(row.date_received).to have_text '2 Mar 2012'
    expect(row.pages).to have_text '92'

    last_row = cases_show_page.data_requests.rows.last
    expect(last_row).not_to have_selector '.total-label'
    expect(last_row.total_label).not_to have_text 'Total'
    expect(last_row).not_to have_selector '.total-value'
    expect(last_row.total_value).not_to have_text '0'

    # Note pre-filled fields when making further update to the same Data Request
    click_link 'Update page count'
    expect(data_request_edit_page).to be_displayed
    expect(data_request_edit_page.form.num_pages.value).to eq '92'
    expect(data_request_edit_page.form.date_received_dd.value).to eq '2'
    expect(data_request_edit_page.form.date_received_mm.value).to eq '3'
    expect(data_request_edit_page.form.date_received_yyyy.value).to eq '2012'
  end

  scenario 'partial data entry fails' do
    cases_show_page.load(id: offender_sar_case.id)
    click_link 'Update page count'

    data_request_edit_page.form.num_pages.fill_in(with: 3)
    click_on 'Update data received'

    expect(data_request_edit_page).to be_displayed
    expect(data_request_edit_page).to have_text "Date received can't be blank"
  end

  scenario 'unchanged data entry remains unprocessed' do
    # Programmatically update the latest page count for this DataRequest
    data_request.logs.new(
      user: manager,
      num_pages: 15,
      date_received: Date.new(1983, 11, 14)
    )
    data_request.save!

    cases_show_page.load(id: offender_sar_case.id)
    click_link 'Update page count' # Still only have 1 DataRequest for this case

    # Same values entered as those already last saved
    data_request_edit_page.form.date_received_dd.fill_in(with: 14)
    data_request_edit_page.form.date_received_mm.fill_in(with: 11)
    data_request_edit_page.form.date_received_yyyy.fill_in(with: 1983)
    data_request_edit_page.form.num_pages.fill_in(with: 15)
    click_on 'Update data received'

    expect(data_request_edit_page).to be_displayed
    expect(data_request_edit_page).to have_text 'Ensure either Date received or Number of pages is changed'
  end
end
