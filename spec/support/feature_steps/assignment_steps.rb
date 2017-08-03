def assign_case(expected_business_unit, expected_save_flash_msg='Case successfully created')
  # Browse Business Group
  assignments_new_page.choose_business_group(expected_business_unit.business_group)

  # Select Business Unit
  assignments_new_page.choose_business_unit(expected_business_unit)

  expect(cases_show_page.text).to have_content(expected_save_flash_msg)

  expect(cases_show_page.case_status.details.copy.text).to eq "To be accepted"

  expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq expected_business_unit.name


end
