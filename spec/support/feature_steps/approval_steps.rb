def approve_case(kase:, expected_team:, expected_status:)
  cases_show_page.actions.clear_case.click
  expect(approve_response_page)
    .to be_displayed(id: kase.id)
  expect(approve_response_page.clearance.expectations.team.text)
    .to eq expected_team.name
  expect(approve_response_page.clearance.expectations.status.text)
    .to eq expected_status
end

def approve_response(kase:)
  approve_response_page.submit_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first)
    .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
end

def select_case_on_open_cases_page(kase:, expected_team:)
  open_cases_page.click_on kase.number
  expect(cases_show_page.case_status.details.who_its_with.text)
    .to eq expected_team.name
end

