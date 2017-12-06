UPLOAD_RESPONSE_DOCX_FIXTURE = Rails.root.join 'spec/fixtures/response.docx'

def upload_response_step(file: UPLOAD_RESPONSE_DOCX_FIXTURE)
  stub_s3_uploader_for_all_files!
  cases_show_page.actions.upload_response.click
  cases_new_response_upload_page.drop_in_dropzone(file)
  cases_new_response_upload_page.upload_response_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first.heading)
    .to have_text 'You have uploaded the response for this case.'
end

def mark_as_sent_step
  cases_show_page.actions.mark_as_sent.click

  cases_respond_page.mark_as_sent_button.click

  expect(open_cases_page)
    .to have_content("Response confirmed. The case is now with DACU.")
  expect(cases_show_page.case_status.details.who_its_with.text)
    .to eq 'Disclosure BMT'
  expect(cases_show_page.case_status.details.copy.text).to eq 'Ready to close'
end

def close_case_step
  cases_show_page.actions.close_case.click

  cases_close_page.fill_in_date_responded(Date.today)

  cases_close_page.is_info_held.yes.click

  cases_close_page.wait_until_outcome_visible

  cases_close_page.outcome.granted_in_full.click

  cases_close_page.submit_button.click

  expect(cases_show_page).to have_content("You've closed this case")

  expect(cases_show_page.case_status.details.copy.text).to eq "Case closed"
end

# def upload_changes_for_redraft(kase:,
#                                response_attachments:,
#                                expected_team:,
#                                expected_status:)
#   cases_show_page.actions.upload_redraft.click
#   expect(cases_new_response_upload_page).to be_displayed(id: kase.id)
#   expect(cases_new_response_upload_page.clearance.expectations.team.text)
#     .to eq expected_team.name
#   expect(cases_new_response_upload_page.clearance.expectations.status.text)
#     .to eq expected_status
#   response_attachments.each do |file|
#     cases_new_response_upload_page.drop_in_dropzone file
#   end
# end

# # rubocop:disable Metrics/ParameterLists
# def submit_changes_for_redraft(kase:,
#                                expected_notice:,
#                                expected_team:,
#                                expected_status:,
#                                expected_attachments:,
#                                expected_history:)
#   cases_new_response_upload_page.upload_response_button.click
#   expect(cases_show_page).to be_displayed(id: kase.id)
#   expect(cases_show_page.notice).to have_content(expected_notice)
#   expect(cases_show_page.case_status.details.who_its_with)
#     .to have_text(expected_team.name)
#   expect(cases_show_page.case_status.details.copy)
#     .to have_text(expected_status)
#   expected_attachments.each do |attachment|
#     expect(cases_show_page.case_attachments.first.collection.first.filename)
#       .to have_text(attachment)
#   end
#   expect(cases_show_page.case_history.entries.first)
#     .to have_text(expected_history)
# end
# # rubocop:enable Metrics/ParameterLists

