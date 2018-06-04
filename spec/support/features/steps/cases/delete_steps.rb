def delete_case_step(kase:)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page).to have_delete_case

  cases_show_page.delete_case.click
  expect(confirm_destroy_page).to be_displayed

  confirm_destroy_page.confirm_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first.heading.text)
    .to eq "You have deleted case #{kase.number}."
  expect(open_cases_page.case_numbers).not_to include(kase.number)
end
