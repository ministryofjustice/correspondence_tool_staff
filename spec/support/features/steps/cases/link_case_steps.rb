def link_a_case_step(kase:, kase_for_link: create(:accepted_case))
  open_cases_page.load
  click_link kase.number
  expect(cases_show_page).to be_displayed

  cases_show_page.link_case.action_link.click
  expect(cases_new_case_link_page).to be_displayed(id: kase.id)

  cases_new_case_link_page.create_a_new_case_link(kase_for_link.number)
  expect(cases_show_page).to be_displayed(id: kase.id)
  expect(cases_show_page.notice.text).to eq "Case #{kase_for_link.number} has been linked to this case"

  cases_show_page.link_case.linked_records.first.link.click
  expect(cases_show_page).to be_displayed(id: kase_for_link.id)

  cases_show_page.link_case.linked_records.first.link.click
end
