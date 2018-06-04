def edit_case_step(kase:, subject: nil)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.case_details).to have_edit_case
  cases_show_page.case_details.edit_case.click

  cases_edit_page.foi_detail.subject.set subject if subject
  cases_edit_page.submit_button.click

  if subject
    expect(cases_show_page.page_heading.heading.text)
        .to eq "Case subject, #{subject}"
  end
end

def edit_case_closure_step(kase:, date_responded: Date.today, tmm: false)
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

  cases_edit_closure_page.submit_button.click
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.notice.text)
    .to eq 'You have updated the closure details for this case.'
  expect(cases_show_page.case_details.response_details.date_responded.data.text)
    .to eq date_responded.strftime(Settings.default_date_format)
  if tmm
    expect(cases_show_page.case_details.response_details.refusal_reason.data.text)
      .to eq '(s1(3)) - Clarification required'
  end
end
