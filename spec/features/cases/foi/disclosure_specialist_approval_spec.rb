require 'rails_helper'

feature 'cases requiring clearance by disclosure specialist' do
  given(:manager) { create :manager }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:responding_team) { create :responding_team }
  given!(:team_dacu_disclosure) { create :team_dacu_disclosure }

  def create_case(flag_for_clearance: false)
    expect(cases_new_page).to be_displayed
    cases_new_page.fill_in_case_details
    cases_new_page.flag_for_disclosure_specialists.choose(
      flag_for_clearance ? 'Yes' : 'No'
    )
    cases_new_page.submit_button.click
  end

  def assign_case_to_team(team:)
    expect(assignments_new_page).to be_displayed
    assignments_new_page.assign_to.choose team.name
    assignments_new_page.create_and_assign_case.click
  end

  scenario 'flagging a case on creation' do
    login_as manager

    cases_page.load
    cases_page.new_case_button.click

    create_case(flag_for_clearance: true)
    assign_case_to_team(team: responding_team)
    expect(cases_show_page).to be_displayed
    expect(cases_show_page.case_history.entries.last.text)
      .to include('Flag for clearance')

    kase = Case.last

    ## DISCLOSURE SPECIALIST ###############################
    login_as disclosure_specialist

    incoming_cases_page.load
    expect(incoming_cases_page.case_list.size).to eq 1
    expect(incoming_cases_page.case_list.first.number.text)
      .to have_content kase.number
  end
end
