def approve_case(kase:, expected_team:, expected_status:)
  cases_show_page.actions.clear_case.click
  expect(approve_response_page)
    .to be_displayed(id: kase.id)
  expect(approve_response_page.clearance.expectations.team.text)
    .to eq expected_team.name
  expect(approve_response_page.clearance.expectations.status.text)
    .to eq expected_status
end

def request_amends(kase:, expected_team:, expected_status:, expected_action: nil)
  cases_show_page.actions.request_amends.click
  expect(request_amends_page)
    .to be_displayed(id: kase.id)
  expect(request_amends_page.clearance.action)
    .to have_text(expected_action) if expected_action
  expect(request_amends_page.clearance.expectations.team.text)
    .to eq expected_team.name
  expect(request_amends_page.clearance.expectations.status.text)
    .to eq expected_status
end

def approve_response(kase:)
  approve_response_page.submit_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first)
    .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
end

def execute_request_amends(kase:)
  request_amends_page.submit_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first)
    .to have_text "You have requested amends to case #{kase.number} - #{kase.subject}"
end

def select_case_on_open_cases_page(kase:, **expectations)
  open_cases_page.click_on kase.number
  expect_case_details_on_cases_show_page(expectations)
end

def select_case_on_incoming_cases_page(kase:, **expectations)
  incoming_cases_page.click_on kase.number
  expect_case_details_on_cases_show_page(expectations)
end

def expect_case_details_on_cases_show_page(expected_team: nil,
                                           expected_history: nil)
  if expected_team.present?
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq expected_team.name
  end

  if expected_history.present?
    history_entries = cases_show_page.case_history.entries
    history_entries.zip(expected_history).each do |entry, expected_text|
      expect(entry).to have_text(expected_text)
    end
  end
end

