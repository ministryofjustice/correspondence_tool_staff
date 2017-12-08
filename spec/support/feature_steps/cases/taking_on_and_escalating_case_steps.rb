def take_on_case_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.take_on_case.click
  row.actions.wait_until_success_message_visible
  expect(row.actions.success_message.text)
    .to eq "Case taken on Undo taking on of case #{kase.number}"
end

