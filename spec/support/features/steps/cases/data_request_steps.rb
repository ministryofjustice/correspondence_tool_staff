def record_a_data_request_of_nomis_other(checked_case, request_values)
  cases_show_page.load(id: checked_case.id)
  click_on "Record data request"

  click_on "Find an address"
  click_on "Use #{request_values[:location]}"
  data_request_page.form.choose_request_type("nomis_other")
  data_request_page.form.request_type_note_for_nomis.fill_in(with: request_values[:request_type_note])
  data_request_page.form.set_date_requested(request_values[:date_requested])
  click_on "Continue"
end

def validate_nomis_other_info(request_values)
  expect(cases_show_page).to be_displayed
  row = cases_show_page.data_requests.rows[0]
  expect(row.location).to have_text request_values[:location]
  expect(row.request_type).to have_text "NOMIS other"
  expect(row.request_type).to have_text request_values[:request_type_note]
  expect(row.date_requested).to have_text request_values[:date_requested].strftime(Settings.default_date_format)
  data_requests = cases_show_page.data_requests.rows
  expect(data_requests.size).to eq 1
end
