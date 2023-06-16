def filter_on_type_step(page:, expected_cases:, types: [], sensitivity: [])
  page.filter_on("type", *types)
  page.filter_on("sensitivity", *sensitivity)

  expect(page.case_numbers).to eq expected_cases.map(&:number)
  cases_found_message = if expected_cases.count == 1
                          "1 case found"
                        else
                          "#{expected_cases.count} cases found"
                        end
  expect(page.search_results_count.text).to eq cases_found_message

  page.open_filter(:type)
  types.each do |type|
    element_name = "#{type}_checkbox"
    expect(page.filter_type_content.__send__(element_name))
      .to be_checked
  end
  page.open_filter(:sensitivity)
  sensitivity.each do |option|
    element_name = "#{option}_checkbox"
    expect(page.filter_sensitivity_content.__send__(element_name))
      .to be_checked
  end
end
