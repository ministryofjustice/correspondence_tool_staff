def assign_case_step(business_unit:,
                     expected_status: "To be accepted",
                     expected_to_be_with: "%{business_unit_name}",
                     expected_flash_msg: "Case assigned to #{business_unit.name}",
                     assigning_page: assignments_new_page)
  # Browse Business Group
  assigning_page.choose_business_group(business_unit.business_group)

  # Select Business Unit
  assigning_page.choose_business_unit(business_unit)

  expect(cases_show_page.notice.text).to have_content(expected_flash_msg)

  expect(cases_show_page.case_status.details.copy.text).to eq expected_status

  expected_to_be_with_text = sprintf(expected_to_be_with, business_unit_name: business_unit.name)
  unless cases_show_page.case_status.details.copy.text == "Closed"
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq expected_to_be_with_text
  end
  expect(cases_show_page.case_details.responders_details.team.data.text)
    .to eq expected_to_be_with_text
end

def accept_responder_assignment_step
  assignments_edit_page.accept_radio.click
  assignments_edit_page.confirm_button.click
  expect(cases_show_page).to have_happy_action_notice
  expect(cases_show_page.happy_action_notice.text)
    .to have_text "You've accepted this case\nIt will now appear in your cases."
  expect(cases_show_page.happy_action_notice.text)
    .to have_text "It will now appear in your cases."
  expect(cases_show_page.case_status.details.copy.text)
    .to eq "Draft in progress"
end
