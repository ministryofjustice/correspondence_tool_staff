require "rails_helper"

feature "cases requiring clearance by disclosure specialist" do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [team_dacu] }
  given(:disclosure_specialist)       { find_or_create :disclosure_specialist }
  given(:other_disclosure_specialist) do
    create :approver,
           approving_team: team_dacu_disclosure
  end
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }
  given(:responder)                   { responding_team.users.first }

  scenario "taking_on, undoing and de-escalating a case as a disclosure specialist", js: true do
    kase = create :case_being_drafted, :flagged,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase:)
    undo_taking_case_on_step(kase:)
    de_escalate_case_step(kase:)
    expect(kase.reload.approver_assignments).to be_blank
    undo_de_escalate_case_step(kase:)
  end

  scenario "approving a case as a disclosure specialist not assigned directly to the case", js: true do
    kase = create :pending_dacu_clearance_case,
                  responder:,
                  responding_team:,
                  approver: disclosure_specialist

    login_as other_disclosure_specialist
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).not_to have_clear_case
  end

  scenario "upload a response and approve case as a disclosure specialist", js: true do
    kase = create :pending_dacu_clearance_case,
                  responder:,
                  responding_team:,
                  approver: disclosure_specialist

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.actions).to have_upload_approve
    cases_show_page.actions.upload_approve.click

    expect(cases_upload_response_and_approve_page).to be_displayed

    upload_file = "#{Faker::Internet.slug}.jpg"
    cases_upload_response_and_approve_page.upload_file(
      kase:,
      file_path: upload_file,
    )

    cases_upload_response_and_approve_page.upload_response_button.click

    expect(cases_show_page).to be_displayed(id: kase.id)
    expect(cases_show_page.case_attachments[0].collection[0].filename.text)
      .to eq upload_file
    expect(cases_show_page.case_status.details.copy.text).to eq "Ready to send"
    expect(cases_show_page.case_status.details.who_its_with.text).to eq responding_team.name
  end

  scenario "upload a response and remove clearance as a disclosure specialist", js: true do
    kase = create :pending_dacu_clearance_case,
                  responder:,
                  responding_team:,
                  approver: disclosure_specialist

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.clearance_levels.basic_details.dacu_disclosure.remove_clearance.text).to eq(
      "Remove clearance",
    )
    cases_show_page.clearance_levels.basic_details.dacu_disclosure.remove_clearance.find_link.click
    expect(page).to have_current_path(remove_clearance_case_path(kase))
    fill_in "Reason for removing clearance", with: "reason"
    cases_remove_clearance_form_page.submit_button.click
    expect(cases_show_page.notice.text).to eq "Clearance removed for this case."
  end

  scenario "upload a response and return for redraft", js: true do
    kase = create :pending_dacu_clearance_case, approver: disclosure_specialist

    login_as disclosure_specialist
    cases_show_page.load(id: kase.id)
    cases_show_page.actions.upload_redraft.click

    expect(cases_upload_response_and_return_for_redraft_page).to be_displayed

    upload_file = "#{Faker::Internet.slug}.jpg"
    cases_upload_response_and_return_for_redraft_page.upload_file(
      kase:,
      file_path: upload_file,
    )

    cases_upload_responses_page.upload_response_button.click

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_attachments[0].collection[0].filename.text)
      .to eq upload_file
    expect(cases_show_page.case_status.details.copy.text).to eq "Draft in progress"
    expect(cases_show_page.case_status.details.who_its_with.text).to eq kase.responding_team.name
  end

  scenario "approving a case and bypassing press and private clearance", js: true do
    kase = create :pending_dacu_clearance_case_flagged_for_press_and_private, approver: disclosure_specialist
    responding_team = kase.responding_team
    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    approve_case_with_bypass(kase:, expected_team: responding_team, expected_status: "Ready to send")
  end

  scenario "approving a case and bypassing clearance with upload", js: true do
    kase = create :pending_dacu_clearance_case_flagged_for_press_and_private, approver: disclosure_specialist
    responding_team = kase.responding_team
    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    approve_upload_case_with_bypass(kase:, expected_team: responding_team, expected_status: "Ready to send")
  end
end
