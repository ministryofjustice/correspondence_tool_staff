UPLOAD_RESPONSE_DOCX_FIXTURE = Rails.root.join "spec/fixtures/response.docx"

def upload_response_step(file: UPLOAD_RESPONSE_DOCX_FIXTURE)
  stub_s3_uploader_for_all_files!
  cases_show_page.actions.upload_response.click
  cases_upload_responses_page.drop_in_dropzone(file)
  cases_upload_responses_page.upload_response_button.click
  expect(cases_show_page).to be_displayed
  expect(cases_show_page.notice)
      .to have_text "You have uploaded the response for this case."
end

def upload_ico_decision_and_close_step(file: UPLOAD_RESPONSE_DOCX_FIXTURE)
  stub_s3_uploader_for_all_files!
  cases_close_page.ico.drop_in_dropzone(file)
  cases_upload_responses_page.upload_response_button.click
  expect(cases_show_page).to be_displayed
  expect(cases_show_page.notice)
      .to have_text "You've closed this case"
end

def mark_case_as_sent_step(responded_date:,
                           expected_status:,
                           expected_to_be_with:)
  cases_show_page.actions.mark_as_sent.click
  cases_respond_page.fill_in_date_responded(responded_date)
  cases_respond_page.submit_button.click
  expect(open_cases_page)
    .to have_content("The response has been marked as sent.")
  expect(cases_show_page.case_status.details.who_its_with.text)
    .to eq expected_to_be_with
  expect(cases_show_page.case_status.details.copy.text).to eq expected_status
end

def close_case_step(responded_date: Time.zone.today)
  cases_show_page.actions.close_case.click
  cases_close_page.fill_in_date_responded(responded_date)
  cases_close_page.click_on "Continue"
  expect(cases_closure_outcomes_page).to be_displayed
  cases_closure_outcomes_page.is_info_held.yes.click
  cases_closure_outcomes_page.wait_until_outcome_visible
  cases_closure_outcomes_page.outcome.granted_in_full.click
  cases_closure_outcomes_page.submit_button.click
  expect(cases_show_page).to have_content("You've closed this case")
  expect(cases_show_page.case_status.details.copy.text).to eq "Closed"
end

def close_sar_case_step(timeliness: "in time", tmm: false, editable: true)
  cases_show_page.actions.close_case.click
  cases_close_page.fill_in_date_responded(Time.zone.today)
  cases_close_page.click_on "Continue"
  expect(cases_closure_outcomes_page).to be_displayed

  if tmm
    cases_close_page.missing_info.yes.click
  else
    cases_close_page.missing_info.no.click
  end

  cases_close_page.click_on "Close case"
  show_page = cases_show_page.case_details

  if editable
    expect(cases_show_page.notice.text).to eq("You've closed this case. Edit case closure details")
  else
    expect(cases_show_page.notice.text).to eq("You've closed this case")
  end

  expect(show_page.response_details.date_responded.data.text).to eq Time.zone.today.strftime(Settings.default_date_format)
  expect(show_page.response_details.timeliness.data.text).to eq "Answered #{timeliness}"

  # Regex required to handle both cases of 1 or more days to respond

  if show_page.has_css?(".overturned-sar-basic-details")
    expect(show_page.response_details.time_taken.data.text).to match(/\d+ working day[s{1}]?/)
  end

  if tmm
    expect(show_page.response_details.refusal_reason.data.text).to eq "SAR Clarification/Tell Me More"
  else
    expect(show_page.response_details).to have_no_refusal_reason
  end
end

def close_ico_appeal_case_step(timeliness: "in time", decision: "upheld")
  cases_show_page.actions.close_case.click
  expect(cases_close_page).to be_displayed
  cases_close_page.fill_in_ico_date_responded(Time.zone.today)
  cases_close_page.click_on "Continue"

  case decision
  when "upheld"
    cases_close_page.ico_decision.upheld.click
  when "overturned"
    cases_close_page.ico_decision.overturned.click
  end

  upload_ico_decision_and_close_step

  show_page = cases_show_page.case_details
  expect(cases_show_page.notice.text).to eq("You've closed this case")
  expect(show_page.response_details.date_responded.data.text)
    .to eq Time.zone.today.strftime(Settings.default_date_format)
  expect(show_page.response_details.timeliness.data.text)
    .to eq "Answered #{timeliness}"
  expect(show_page.response_details.time_taken.data.text).to match(/\d+ working days?/)
  expect(show_page.response_details).to have_no_refusal_reason
end
