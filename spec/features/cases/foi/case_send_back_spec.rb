require "rails_helper"

feature "Send back a case for change" do
  given(:manager)         { find_or_create :disclosure_bmt_user }

  background do
    login_as manager
  end

  scenario "manager send back a non-triggered which is ready to close" do
    non_triggered_case_ready_to_closed = create :responded_case, :dacu_disclosure
    send_back(non_triggered_case_ready_to_closed, "send back a non-triggered which is ready to close")
  end

  scenario "manager send back a triggered case which is ready to close" do
    triggered_case_ready_to_closed = create :responded_case, :flagged
    check_approver_assignments(triggered_case_ready_to_closed)
    send_back(triggered_case_ready_to_closed, "send back a triggered case which is ready to close")
    validate_approver_assignments(triggered_case_ready_to_closed)
  end

  scenario "manager send back a triggered case which is ready to send" do
    triggered_case_ready_to_send = create :approved_case, :flagged
    check_approver_assignments(triggered_case_ready_to_send)
    send_back(triggered_case_ready_to_send, "send back a triggered case which is ready to send")
    validate_approver_assignments(triggered_case_ready_to_send)
  end

private

  def send_back(kase, message)
    cases_show_page.load(id: kase.id)

    cases_show_page.actions.send_back.click
    expect(case_send_back_page).to be_displayed
    case_send_back_page.fill_in_optional_message(message)
    case_send_back_page.submit_button.click
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_text message

    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
      .to eq "Case was sent back for change"
  end

  def check_approver_assignments(kase)
    kase.approver_assignments.each do |assignment|
      expect(assignment.approved).to eq true
    end
  end

  def validate_approver_assignments(kase)
    kase.reload
    kase.approver_assignments.each do |assignment|
      expect(assignment.approved).to eq false
    end
  end
end
