require "rails_helper"

feature "Requesting further clearance on an unflagged case" do
  given(:manager) { find_or_create :disclosure_bmt_user }
  given(:case_being_drafted) { create :case_being_drafted }
  given(:assigned_case) { create :awaiting_responder_case }
  given(:ready_to_send_case) { create :ready_to_send_case }

  background do
    login_as manager
  end

  scenario "manager requests clearance on a case with responder" do
    cases_show_page.load(id: case_being_drafted.id)
    expect(cases_show_page.case_details.foi_basic_details.case_type.text).to eq "Case typeFOI"
    cases_show_page.clearance_levels.escalate_link.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
        .to eq "Clearance level added"
    event_row = cases_show_page.case_history.rows[1]
    expect(event_row.details.event.text)
      .to eq "Request further clearance"
    trigger_details = cases_show_page.case_details.foi_basic_details.case_type.foi_trigger.text
    expect(trigger_details).to eq "This is a Trigger case"
  end

  scenario "manager requests clearance on an unaccepted case" do
    cases_show_page.load(id: assigned_case.id)
    expect(cases_show_page.case_details.foi_basic_details.case_type.text).to eq "Case typeFOI"
    cases_show_page.clearance_levels.escalate_link.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
        .to eq "Clearance level added"
    event_row = cases_show_page.case_history.rows[1]
    expect(event_row.details.event.text)
      .to eq "Request further clearance"
    trigger_details = cases_show_page.case_details.foi_basic_details.case_type.foi_trigger.text
    expect(trigger_details).to eq "This is a Trigger case"
  end

  scenario "manager requests clearance on an ready-to-send case" do
    cases_show_page.load(id: ready_to_send_case.id)
    expect(cases_show_page.case_details.foi_basic_details.case_type.text).to eq "Case typeFOI"
    cases_show_page.clearance_levels.escalate_link.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
        .to eq "Clearance level added"
    event_row = cases_show_page.case_history.rows[1]
    expect(event_row.details.event.text)
      .to eq "Request further clearance"
    trigger_details = cases_show_page.case_details.foi_basic_details.case_type.foi_trigger.text
    expect(trigger_details).to eq "This is a Trigger case"
    ready_to_send_case.reload
    expect(cases_show_page.case_status.details.copy.text).to eq "Pending clearance"
    expect(ready_to_send_case.current_state).to eq "pending_dacu_clearance"
  end
end
