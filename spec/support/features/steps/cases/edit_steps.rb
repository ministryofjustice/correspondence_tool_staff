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
