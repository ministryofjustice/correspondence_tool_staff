def approve_case_step(kase:, expected_team:, expected_status:)
  cases_show_page.actions.clear_case.click
  expect(approve_response_interstitial_page).to be_displayed

  if approve_response_interstitial_page.has_bypass_press_option?
    approve_response_interstitial_page.bypass_press_option.radio_yes.click
    expect(approve_response_interstitial_page.bypass_press_option)
        .to have_no_bypass_reason_text
  end

  approve_response_interstitial_page.clear_response_button.click
  expect(cases_show_page).to be_displayed(id: kase.id)
  open_cases_page.load
  case_row = open_cases_page.case_list.detect{ |r| r.number.text == "Link to case #{kase.number}" }
  expect(case_row.who_its_with.text).to eq expected_team.name
  expect(case_row.status.text).to eq expected_status
end


def approve_case_with_bypass(kase:, expected_team:, expected_status:)
  cases_show_page.actions.clear_case.click
  expect(approve_response_interstitial_page).to be_displayed
  expect(approve_response_interstitial_page).to have_bypass_press_option
  approve_response_interstitial_page.bypass_press_option.radio_no.click
  expect(approve_response_interstitial_page.bypass_press_option)
      .to have_bypass_reason_text
  approve_response_interstitial_page.bypass_press_option.bypass_reason_text.set 'No Presss office approval required'
  approve_response_interstitial_page.clear_response_button.click

  expect(cases_show_page).to be_displayed(id: kase.id)
  open_cases_page.load
  case_row = open_cases_page.case_list.detect{ |r| r.number.text == "Link to case #{kase.number}" }
  expect(case_row.who_its_with.text).to eq expected_team.name
  expect(case_row.status.text).to eq expected_status
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
  approve_response_interstitial_page.clear_response_button.click
  # approve_response_page.submit_button.click
  expect(open_cases_page).to be_displayed
  expect(open_cases_page.notices.first)
    .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
end

def execute_request_amends
  request_amends_page.submit_button.click
  expect(cases_show_page).to be_displayed
  expect(cases_show_page.notice)
    .to have_text 'You have requested amends to this case\'s response.'
end

