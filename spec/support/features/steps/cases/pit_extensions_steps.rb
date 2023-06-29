def extend_for_pit_step(kase:, new_deadline:)
  expect(cases_show_page).to be_displayed(id: kase.id)
  cases_show_page.extend_for_pit_action.click
  expect(cases_extend_for_pit_page).to be_displayed(id: kase.id)
  cases_extend_for_pit_page.fill_in_extension_date(new_deadline)
  cases_extend_for_pit_page.reason_for_extending
    .set "Extending to #{new_deadline} for testing"
  cases_extend_for_pit_page.submit_button.click
  extend_for_pit_row = cases_show_page.case_history.row_for_event(
    "Extended for Public Interest Test (PIT)",
  )
  expect(extend_for_pit_row)
    .to have_content "Extending to #{new_deadline} for testing"
end
