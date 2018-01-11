def create_case_step(type: 'casefoistandard',
                     delivery_method: :sent_by_email,
                     uploaded_request_files: [],
                     flag_for_disclosure: false)

  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click

  expect(cases_select_type_page).to be_displayed

  cases_select_type_page.fill_in_case_type('casefoistandard')

  expect(cases_new_page).to be_displayed
  cases_new_page.fill_in_case_details(
    type: type,
    delivery_method: delivery_method,
    uploaded_request_files: uploaded_request_files
  )
  cases_new_page.choose_flag_for_disclosure_specialists(
    flag_for_disclosure ? 'yes' : 'no'
  )
  click_button 'Next - Assign case'

  # Return the case we created using the params of the current  path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  Case::Base.find(kase_id)
end
