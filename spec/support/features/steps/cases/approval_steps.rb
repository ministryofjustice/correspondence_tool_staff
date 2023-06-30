def approve_case_step(kase:,
                      expected_team:,
                      expected_status:,
                      expected_notice: "#{expected_team.name} has been notified that the response is ready to send.")
  cases_show_page.actions.clear_case.click
  expect(cases_approve_page).to be_displayed

  if cases_approve_page.has_bypass_press_option?
    cases_approve_page.bypass_press_option.radio_yes.click
    expect(cases_approve_page.bypass_press_option)
      .to have_no_bypass_reason_text
  end

  cases_approve_page.clear_response_button.click
  expect(cases_show_page).to be_displayed(id: kase.id)
  unless expected_notice.nil?
    expect(cases_show_page.notice.text)
      .to eq sprintf(expected_notice, number: kase.number, subject: kase.subject)
  end

  open_cases_page.load

  expect(open_cases_page).to be_displayed
  case_row = open_cases_page.row_for_case_number(kase.number)
  expect(case_row.who_its_with.text).to eq expected_team.name
  expect(case_row.status.text).to eq expected_status
end

def approve_case_with_bypass(kase:, expected_team:, expected_status:)
  cases_show_page.actions.clear_case.click
  expect(cases_approve_page).to be_displayed
  expect(cases_approve_page).to have_bypass_press_option
  cases_approve_page.bypass_press_option.radio_no.click
  expect(cases_approve_page.bypass_press_option)
      .to have_bypass_reason_text
  cases_approve_page.bypass_press_option.bypass_reason_text.set "No Press office approval required"
  cases_approve_page.clear_response_button.click

  expect(cases_show_page).to be_displayed(id: kase.id)
  open_cases_page.load
  case_row = open_cases_page.row_for_case_number(kase.number)
  expect(case_row.who_its_with.text).to eq expected_team.name
  expect(case_row.status.text).to eq expected_status
end

def approve_upload_case_with_bypass(kase:, expected_team:, expected_status:)
  stub_s3_uploader_for_all_files!

  cases_show_page.actions.upload_approve.click
  expect(cases_upload_response_and_approve_page).to be_displayed
  expect(cases_upload_response_and_approve_page).to have_bypass_press_option
  cases_upload_response_and_approve_page.bypass_press_option.radio_no.click
  expect(cases_upload_response_and_approve_page.bypass_press_option)
      .to have_bypass_reason_text
  cases_upload_response_and_approve_page.bypass_press_option.bypass_reason_text.set "No Press office approval required"
  cases_upload_response_and_approve_page.drop_in_dropzone(UPLOAD_RESPONSE_DOCX_FIXTURE)
  cases_upload_response_and_approve_page.upload_response_button.click

  expect(cases_show_page).to be_displayed(id: kase.id)
  open_cases_page.load
  case_row = open_cases_page.row_for_case_number(kase.number)
  expect(case_row.who_its_with.text).to eq expected_team.name
  expect(case_row.status.text).to eq expected_status
end

def request_amends(kase:, expected_team:, expected_status:, expected_action: nil)
  cases_show_page.actions.request_amends.click
  expect(request_amends_page)
    .to be_displayed(id: kase.id)
  if expected_action
    expect(request_amends_page.clearance.action)
      .to have_text(expected_action)
  end
  expect(request_amends_page.clearance.expectations.team.text)
    .to eq expected_team.name
  expect(request_amends_page.clearance.expectations.status.text)
    .to eq expected_status
end

def execute_request_amends(expected_flash: "You have requested amends to this case's response.")
  request_amends_page.submit_button.click
  expect(cases_show_page).to be_displayed
  expect(cases_show_page.notice)
    .to have_text expected_flash
end
