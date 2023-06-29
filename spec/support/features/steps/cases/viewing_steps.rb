def go_to_case_details_step(kase:,
                            page: nil,
                            expected_response_files: nil,
                            expected_team: nil,
                            expected_history: nil,
                            find_details_page: true)
  if find_details_page
    page ||= cases_page
    page.click_on kase.number
  end

  expect(cases_show_page.displayed? || assignments_edit_page.displayed?)
      .to be_truthy

  if expected_response_files.present?
    expected_response_files.each do |file|
      response_collection = cases_show_page.collection_for_case_attachment(file)
      expect(response_collection).not_to be_blank
    end
  end

  if expected_team.present?
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq expected_team.name
  end

  if expected_history.present?
    history_entries = cases_show_page.case_history.entries
    history_entries.zip(expected_history).each do |entry, expected_text|
      expect(entry).to have_text(expected_text) if expected_text
    end
  end
end

def go_to_incoming_cases_step(expect_not_to_see_cases: [])
  cases_page.homepage_navigation.new_cases.click
  if expect_not_to_see_cases.present?
    expect_not_to_see_cases.each do |kase|
      row_for_case = incoming_cases_page.row_for_case_number(kase.number)
      expect(row_for_case).to be_nil
    end
  end
end
