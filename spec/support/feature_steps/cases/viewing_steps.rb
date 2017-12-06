def view_details_from_open_cases_step(kase:,
                                      expected_response_files: nil)
  cases_page.row_for_case_number(kase.number).number.click
  expect(cases_show_page).to be_displayed(id: kase.id)
  if expected_response_files.present?
    expected_response_files.each do |file|
      response_collection = cases_show_page.collection_for_case_attachment(file)
      expect(response_collection).not_to be_blank
    end
  end
end


def visit_open_cases_page
  visit open_cases_page.url
end
