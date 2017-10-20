def assign_case(expected_business_unit:,
                expected_status: 'To be accepted',
                expected_to_be_with: '%{business_unit_name}',
                expected_flash_msg: 'Case successfully created')
  # Browse Business Group
  assignments_new_page.choose_business_group(expected_business_unit.business_group)

  # Select Business Unit
  assignments_new_page.choose_business_unit(expected_business_unit)

  expect(cases_show_page.text).to have_content(expected_flash_msg)

  expect(cases_show_page.case_status.details.copy.text).to eq expected_status

  expect(cases_show_page.case_status.details.who_its_with.text)
    .to eq expected_to_be_with % { business_unit_name:
                                     expected_business_unit.name }
end
