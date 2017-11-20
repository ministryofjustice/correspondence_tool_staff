def create_case_step(delivery_method: :sent_by_email,
                     uploaded_request_files: [],
                     flag_for_disclosure: false)

  expect(cases_new_page).to be_displayed
  cases_new_page.fill_in_case_details(
    'case',
    delivery_method: delivery_method,
    uploaded_request_files: uploaded_request_files
  )
  cases_new_page.choose_flag_for_disclosure_specialists(
    flag_for_disclosure ? 'yes' : 'no'
  )
  click_button 'Next - Assign case'
end
