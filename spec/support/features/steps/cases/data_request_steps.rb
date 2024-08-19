def record_a_data_request_of_nomis_other(checked_case, request_values)
  data_request_area_show_page.load(case_id: offender_sar_case.id, data_request_area_id: data_request_area.id)
  click_on "Add data request type"

  data_request_page.form.choose_request_type("nomis_other")
  data_request_page.form.request_type_note_for_nomis.fill_in(with: request_values[:request_type_note])
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
