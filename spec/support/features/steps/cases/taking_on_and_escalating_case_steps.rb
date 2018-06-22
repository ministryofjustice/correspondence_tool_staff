def take_on_case_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.take_on_case.click
  row.actions.wait_until_take_on_case_invisible(10)
  expect(row.actions).to have_undo_assign_link
  expect(row.actions.success_message)
    .to have_text "Case taken on Undo taking on of case #{kase.number}"
  expect(row.highlight_row.size).to eq 3
end

def undo_taking_case_on_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.undo_assign_link.click
  row.actions.wait_until_undo_assign_link_invisible(10)
  expect(row.actions).to have_take_on_case
  expect(row.actions).to have_no_success_message
  expect(row).to have_no_highlight_row
end

def de_escalate_case_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.de_escalate_link.click
  row.actions.wait_until_de_escalate_link_invisible(10)
  expect(row.actions).to have_undo_de_escalate_link
  expect(row.actions).to have_no_take_on_case
  expect(row.actions).to have_text 'Case de-escalated Undo'
  expect(row.highlight_row.size).to eq 3
end

def undo_de_escalate_case_step(kase:)
  row = incoming_cases_page.row_for_case_number(kase.number)
  row.actions.undo_de_escalate_link.click
  row.actions.wait_until_undo_de_escalate_link_invisible(10)
  expect(row.actions).to have_de_escalate_link
  expect(row.actions).to have_take_on_case
  expect(row).to have_no_highlight_row
end


