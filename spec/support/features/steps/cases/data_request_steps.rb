def record_a_data_request_of_nomis_other(request_values)
  click_on "Record data request"
  data_request_area_page.form.choose_area_request_type("branston")
  click_on "Continue"

  click_on "Add data request type"

  data_request_page.form.choose_request_type("nomis_other")
  data_request_page.form.request_type_note.fill_in(with: request_values[:request_type_note])
  data_request_page.form.set_date_requested(request_values[:date_requested])
  click_on "Continue"
end

def validate_nomis_other_info(request_values)
  expect(data_request_area_show_page).to be_displayed
  row = data_request_area_show_page.data_requests.rows[0]
  expect(row.request_type).to have_text "NOMIS other"
  expect(row.request_type).to have_text request_values[:request_type_note]
  expect(row.date_requested).to have_text request_values[:date_requested].strftime(Settings.default_date_format)
end
