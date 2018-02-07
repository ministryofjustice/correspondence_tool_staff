def take_on_case_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.take_on_case.click
  sleep 1
  row.actions.wait_until_take_on_case_invisible(10)
  expect(row.actions.success_message.text)
    .to eq "Case taken on Undo taking on of case #{kase.number}"
end

def undo_taking_case_on_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.undo_assign_link.click
  row.actions.wait_until_take_on_case_visible(10)
  row.actions.wait_until_success_message_invisible(10)
end
