require 'rails_helper'


feature 'cases requiring clearance by disclosure specialist' do
  include CaseDateManipulation
  include Features::Interactions

  given(:manager)                     { create :manager, managing_teams: [ team_dacu ] }
  given(:disclosure_specialist)       { create :disclosure_specialist }
  given!(:responding_team)            { create :responding_team }
  given!(:team_dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  given(:team_dacu)                   { find_or_create :team_dacu }

  scenario 'taking_on, undoing and de-escalating a case as a disclosure specialist', js: true do
    kase = create :sar_being_drafted, :flagged,
                  approving_team: team_dacu_disclosure

    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1

    take_on_case_step(kase: kase)
    undo_taking_case_on_step(kase: kase)
    de_escalate_case_step(kase: kase)
    expect(kase.reload.approver_assignments).to be_blank
    undo_de_escalate_case_step(kase: kase)
  end

  scenario 'Disclosure Specialist clears a response response', js: true do
    kase = create :pending_dacu_clearance_sar,
                  approver: disclosure_specialist,
                  responding_team: responding_team

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Disclosure'

    approve_case_step(kase: kase,
                      expected_team: responding_team,
                      expected_status: 'Ready to send')
    go_to_case_details_step(
      kase: kase,
      expected_team: responding_team,
      expected_history: [
        "#{disclosure_specialist.full_name} #{team_dacu_disclosure.name} Response cleared"
      ]
    )
  end

  scenario 'Disclosure Specialist requests amends to a response' do
    kase = create :pending_dacu_clearance_sar, approver: disclosure_specialist, responding_team: responding_team

    login_as disclosure_specialist

    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Disclosure'

    request_amends kase: kase,
                   expected_action: 'requesting amends for',
                   expected_team: responding_team,
                   expected_status: 'Draft in progress'
    execute_request_amends(expected_flash: "Information Officer has been notified a redraft is needed.")
    go_to_case_details_step(
      kase: kase,
      find_details_page: false,
      expected_team: responding_team,
      expected_history: [
        "#{disclosure_specialist.full_name}#{team_dacu_disclosure.name}Request amends"
      ]
    )
  end
end
