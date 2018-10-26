def edit_case_step(kase:, **args)
  case kase.correspondence_type
  when 'foi' then edit_foi_case_step(kase, args)
  when 'ico' then edit_ico_case_step(kase, args)
  end
end

def edit_foi_case_step(kase:, subject:)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_case
  cases_show_page.case_details.edit_case.click

  cases_edit_page.foi_detail.subject.set subject if subject
  cases_edit_page.submit_button.click

  if subject
    expect(cases_show_page.page_heading.heading)
      .to have_copy "Case subject, #{subject}"
  end
end

def edit_ico_case_step(kase:, **params)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_case

  cases_show_page.case_details.edit_case.click
  expect(cases_edit_ico_page).to be_displayed

  cases_edit_ico_page.form.fill_in_case_details(params)
  if params[:original_case].present?
    cases_edit_ico_page.form.add_original_case(params[:original_case])
  end
  cases_edit_ico_page.form.add_related_cases([foi_timeliness_review])

  cases_edit_page.submit_button.click

  if subject
    expect(cases_show_page.page_heading.heading.text)
        .to eq "Case subject, #{subject}"
  end
end

def edit_foi_case_closure_step(kase:, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                               date_responded: Date.today,
                               info_held_status: 'not_confirmed',
                               refusal_reason: 'tmm',
                               outcome: nil,
                               exemptions: [],
                               preselected_exemptions: [])
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_closure

  cases_show_page.case_details.edit_closure.click

  expect(cases_edit_closure_page).to be_displayed
  expect(cases_edit_closure_page.is_info_held.yes).to be_checked
  expect(cases_edit_closure_page.date_responded_day.value)
    .to eq kase.date_responded.day.to_s
  expect(cases_edit_closure_page.date_responded_month.value)
    .to eq kase.date_responded.month.to_s
  expect(cases_edit_closure_page.date_responded_year.value)
    .to eq kase.date_responded.year.to_s
  preselected_exemptions.each do |abbreviation|
    expect(cases_close_page.get_exemption(abbreviation: abbreviation)).to be_checked
  end

  cases_edit_closure_page.fill_in_date_responded(date_responded)

  cases_edit_closure_page.is_info_held.__send__(info_held_status).click

  if refusal_reason
    cases_edit_closure_page.other_reasons.__send__(refusal_reason).click
  end

  if outcome
    cases_edit_closure_page.outcome.__send__(outcome).click
  end

  exemptions.each do |abbreviation|
    cases_edit_closure_page.get_exemption(abbreviation).click
  end

  cases_edit_closure_page.click_on 'Save changes'
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.notice.text)
    .to eq 'You have updated the closure details for this case.'
  expect(cases_show_page.case_details.response_details.date_responded.data.text)
    .to eq date_responded.strftime(Settings.default_date_format)

  info_held_status_object = CaseClosure::InfoHeldStatus.find_by(abbreviation: info_held_status)
  expect(cases_show_page.case_details.response_details.info_held.data.text)
    .to eq info_held_status_object.name

  if refusal_reason
    refusal_reason_object = CaseClosure::RefusalReason.find_by(abbreviation: refusal_reason)
    expect(cases_show_page.case_details.response_details.refusal_reason.data.text)
      .to eq refusal_reason_object.name
  end

  if outcome
    outcome_object = CaseClosure::Outcome.find_by(abbreviation: outcome)
    expect(cases_show_page.case_details.response_details.outcome.data.text)
      .to eq outcome_object.name
  end

  exemptions.each do |abbreviation|
    exemption = CaseClosure::Exemption.find_by(abbreviation: abbreviation)
    expect(cases_show_page.case_details.response_details.exemptions)
      .to have_text exemption.name
  end
end

def edit_sar_case_closure_step(kase:, date_responded: Date.today, tmm: false) # rubocop:disable Metrics/MethodLength
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_closure

  cases_show_page.case_details.edit_closure.click

  expect(cases_edit_closure_page).to be_displayed
  expect(cases_edit_closure_page.date_responded_day.value)
    .to eq kase.date_responded.day.to_s
  expect(cases_edit_closure_page.date_responded_month.value)
    .to eq kase.date_responded.month.to_s
  expect(cases_edit_closure_page.date_responded_year.value)
    .to eq kase.date_responded.year.to_s

  if kase.refusal_reason&.abbreviation == 'tmm'
    expect(cases_edit_closure_page.missing_info.yes).to     be_checked
    expect(cases_edit_closure_page.missing_info.no ).not_to be_checked
  else
    expect(cases_edit_closure_page.missing_info.yes).not_to be_checked
    expect(cases_edit_closure_page.missing_info.no ).to     be_checked
  end

  cases_edit_closure_page.fill_in_date_responded(date_responded)

  if tmm
    cases_edit_closure_page.missing_info.yes.click
  else
    cases_edit_closure_page.missing_info.no.click
  end

  cases_edit_closure_page.click_on 'Save changes'
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.notice.text)
    .to eq 'You have updated the closure details for this case.'
  expect(cases_show_page.case_details.response_details.date_responded.data.text)
    .to eq date_responded.strftime(Settings.default_date_format)
  if tmm
    expect(cases_show_page.case_details.response_details.refusal_reason.data.text)
      .to eq 'SAR Clarification/Tell Me More'
  end
end

def edit_ico_case_closure_step(kase:, decision_received_date: Date.today, ico_decision: 'upheld') # rubocop:disable Metrics/CyclomaticComplexity,  Metrics/MethodLength
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_closure

  cases_show_page.case_details.edit_closure.click

  expect(cases_edit_closure_page).to be_displayed
  expect(cases_edit_closure_page.date_responded_day_ico.value)
    .to eq kase.date_ico_decision_received.day.to_s
  expect(cases_edit_closure_page.date_responded_month_ico.value)
    .to eq kase.date_ico_decision_received.month.to_s
  expect(cases_edit_closure_page.date_responded_year_ico.value)
    .to eq kase.date_ico_decision_received.year.to_s

  if kase.ico_decision == 'upheld'
    expect(cases_edit_closure_page.ico_decision.upheld).to be_checked
    expect(cases_edit_closure_page.ico_decision.overturned ).not_to be_checked
  elsif kase.ico_decision == 'overturned'
    expect(cases_edit_closure_page.ico_decision.upheld).not_to be_checked
    expect(cases_edit_closure_page.ico_decision.overturned ).to be_checked
  end

  cases_edit_closure_page.fill_in_ico_date_responded(decision_received_date)

  if ico_decision == 'upheld'
    cases_edit_closure_page.ico_decision.upheld.click
  elsif ico_decision == 'overturned'
    cases_edit_closure_page.ico_decision.overturned.click
  end
  upload_ico_decision_file
  cases_edit_closure_page.click_on 'Save changes'
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.notice.text)
    .to eq 'You have updated the closure details for this case.'
  if ico_decision == 'upheld'
    expect(cases_show_page.ico.case_details.response_details.outcome.data.text)
      .to eq "Upheld by ICO"
  elsif ico_decision == 'overturned'
    expect(cases_show_page.ico.case_details.response_details.outcome.data.text)
      .to eq "Overturned by ICO"
  end
  # Add this test once the date_ico_decision_received field is implemented
  # on the case_show_page
  #
  # expect(cases_show_page.case_details.response_details.date_ico_decision_received.data.text)
  #   .to eq decision_received_date.strftime(Settings.default_date_format)
end

def upload_ico_decision_file(file: UPLOAD_RESPONSE_DOCX_FIXTURE)
  stub_s3_uploader_for_all_files!
  cases_edit_closure_page.drop_in_dropzone(file)
end
