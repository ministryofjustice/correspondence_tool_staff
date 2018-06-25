def filter_on_type_step(page:, types: [], sensitivity: [], expected_cases:)
  page.filter_on('type', *types)
  page.filter_on('type', *sensitivity)

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
    expect(page.type_filter_panel.__send__(element_name))
      .to be_checked
  end
  sensitivity.each do |option|
    element_name = "#{option}_checkbox"
    expect(page.type_filter_panel.__send__(element_name))
      .to be_checked
  end

end
