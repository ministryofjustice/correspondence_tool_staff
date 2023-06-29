require "rails_helper"

feature "cases requiring clearance by disclosure specialist" do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [team_dacu] }
  given(:disclosure_specialist)       { find_or_create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }
  given!(:responding_team)            { create :responding_team }
  given(:responder)                   { responding_team.users.first }

  scenario "taking_on and undoing a case as a disclosure specialist", js: true do
    kase = create :accepted_ico_foi_case,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase:)
    undo_taking_case_on_step(kase:)
  end

  scenario "Disclosure Specialist clears a response", js: true do
    kase = create(:pending_dacu_clearance_ico_foi_case,
                  approver: disclosure_specialist,
                  responding_team:)

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq "Disclosure"

    approve_case_step(kase:,
                      expected_team: team_dacu_disclosure,
                      expected_status: "Ready to send to ICO",
                      expected_notice: "The response has been cleared and is ready to be sent to the ICO")
    go_to_case_details_step(
      kase:,
      expected_team: team_dacu_disclosure,
      expected_history: [
        "#{disclosure_specialist.full_name} #{team_dacu_disclosure.name}\nResponse cleared",
      ],
    )
  end

  scenario "upload a response and return for redraft", js: true do
    kase = create :pending_dacu_clearance_ico_foi_case, approver: disclosure_specialist

    login_as disclosure_specialist
    cases_show_page.load(id: kase.id)
    cases_show_page.actions.upload_redraft.click

    expect(cases_upload_response_and_return_for_redraft_page).to be_displayed
    upload_file = "#{Faker::Internet.slug}.pdf"
    cases_upload_response_and_return_for_redraft_page.upload_file(
      kase:,
      file_path: upload_file,
    )

    cases_upload_response_and_return_for_redraft_page.upload_response_button.click

    expect(cases_show_page).to be_displayed(id: kase.id)
    expect(cases_show_page.case_attachments[0].collection[0].filename.text)
      .to eq upload_file
    expect(cases_show_page.case_status.details.copy.text).to eq "Draft in progress"
    expect(cases_show_page.case_status.details.who_its_with.text).to eq kase.responding_team.name
  end

  scenario "upload a response and approve", js: true do
    kase = create :pending_dacu_clearance_ico_foi_case, approver: disclosure_specialist

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    cases_show_page.actions.upload_approve.click

    expect(cases_upload_response_and_approve_page).to be_displayed

    upload_file = "#{Faker::Internet.slug}.pdf"
    cases_upload_response_and_approve_page.upload_file(
      kase:,
      file_path: upload_file,
    )

    cases_upload_response_and_approve_page.upload_response_button.click

    expect(cases_show_page).to be_displayed(id: kase.id)
    expect(cases_show_page.case_attachments[0].collection[0].filename.text)
      .to eq upload_file
    expect(cases_show_page.case_status.details.copy.text)
      .to eq "Ready to send to ICO"
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq team_dacu_disclosure.name
  end
end
