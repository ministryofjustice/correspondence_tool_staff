require "rails_helper"

feature "respond to responder assignment" do
  given(:responder)       { responding_team.responders.first }
  given(:responding_team) { assigned_case.responding_team }
  given(:assigned_case) do
    create(
      :assigned_case,
      subject: "A message about XYZ",
      message: "I would like to know about XYZ",
    ).decorate
  end

  given(:assignment) do
    assigned_case.responder_assignment
  end

  background do
    login_as responder
    assigned_case
    assignment
  end

  scenario "kilo accepts assignment" do
    assignments_edit_page.load(case_id: assigned_case.id, id: assignment.id)
    choose "Accept"
    expect(assignments_edit_page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :all)
    click_button "Confirm"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content("You've accepted this case")

    expect(assignment.reload.state).to eq "accepted"
    expect(assigned_case.reload.current_state).to eq "drafting"
    expect(assigned_case.responder).to eq responder
  end

  scenario "kilo rejects assignment" do
    assignments_edit_page.load(case_id: assigned_case.id, id: assignment.id)

    choose "Reject"
    expect(page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :visible)
    fill_in "Why are you rejecting this case?", with: "This is not for me"
    click_button "Confirm"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.notice.text).to eq "#{assigned_case.number} has been rejected."

    expect(assigned_case.reload.current_state).to eq "unassigned"
  end

  scenario "kilo rejects assignment but provides no reasons for rejection" do
    assignments_edit_page.load(case_id: assigned_case.id, id: assignment.id)

    choose "Reject"
    expect(page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :visible)
    click_button "Confirm"

    expect(page)
      .to have_current_path accept_or_reject_case_assignment_path(assigned_case, assignment), ignore_query: true
    expect(page.find("#assignment_state_rejected")).to be_checked
    expect(page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :visible)

    expect(Assignment.find(assignment.id).state).to eq "pending"
    expect(assigned_case.reload.current_state).to eq "awaiting_responder"
    expect(page)
      .to have_content("1 error prevented this form from being submitted")
    expect(page)
      .to have_content("Why are you rejecting this case? can't be blank")
  end

  scenario "kilo tries to submit the form without selecting accept / reject" do
    assignments_edit_page.load(case_id: assigned_case.id, id: assignment.id)

    click_button "Confirm"

    expect(page)
      .to have_current_path accept_or_reject_case_assignment_path(assigned_case, assignment), ignore_query: true
    expect(page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :all)
    expect(assignment.state).to eq "pending"
    expect(assigned_case.reload.current_state).to eq "awaiting_responder"
    expect(page)
        .to have_content("1 error prevented this form from being submitted")
    expect(page)
      .to have_content("You must either accept or reject this case")
  end

  scenario "kilo clicks on a link to an assignment that has been rejected" do
    rejected_case = create :case
    rejected_case.assignments << Assignment.new(state: "rejected", team_id: responding_team.id, role: "responding", user_id: nil, approved: false, reasons_for_rejection: "xx")
    rejected_case.assignments << Assignment.new(state: "pending", team_id: responding_team.id, role: "responding", user_id: nil, approved: false)
    rejected_case.current_state = "awaiting_responder"
    rejected_case.save!

    assignments_edit_page.load(case_id: assigned_case.id, id: assignment.id)

    choose "Accept"
    expect(assignments_edit_page)
      .to have_selector("#assignment_reasons_for_rejection", visible: :all)
    click_button "Confirm"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content("You've accepted this case")

    expect(assignment.reload.state).to eq "accepted"
    expect(assigned_case.reload.current_state).to eq "drafting"
    expect(assigned_case.responder).to eq responder
  end

  scenario "kilo clicks on a link to an assignment that has been accepted" do
    assignment_id = assignment.id
    assignment.accept responder

    visit edit_case_assignment_path assigned_case, assignment_id

    expect(page).to have_current_path(case_path(assigned_case, accepted_now: false))
    expect(page).not_to have_content("You've accepted this case")
    expect(page).not_to have_content("This case has already been rejected.")
  end

  scenario "kilo clicks on a link to an assignment that has been deleted" do
    assignment_id = assignment.id
    assignment.accept responder

    assigned_case.deleted = true
    assigned_case.reason_for_deletion = "testing assignment for deleted case"
    assigned_case.save!

    visit edit_case_assignment_path assigned_case, assignment_id

    expect(page).to have_current_path(open_filter_path)
    expect(page).to have_content("Case has been deleted.")
  end
end
