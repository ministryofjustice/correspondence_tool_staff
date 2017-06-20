require 'rails_helper'

feature 'listing open cases on the system' do
  given(:responding_team_a) { create :responding_team,
                                     name: 'Responding Team A' }
  given(:responding_team_b) { create :responding_team,
                                     name: 'Responding Team B' }
  given(:responder_a) { create :responder,
                               full_name: 'Responder A',
                               responding_teams: [responding_team_a] }
  given(:responder_b) { create :responder,
                               full_name: 'Responder B',
                               responding_teams: [responding_team_b] }
  given(:coresponder_a) { create :responder,
                                 full_name: 'Co-Responder A',
                                 responding_teams: [responding_team_a] }
  given(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  given(:disclosure_specialist) { create :disclosure_specialist }

  given(:unassigned_case) { create :case }
  given(:assigned_case_team_a) { create :assigned_case,
                                        responding_team: responding_team_a }
  given(:assigned_case_coresponder_team_a) do
    create :assigned_case,
           responder: coresponder_a,
           responding_team: responding_team_a
  end
  given(:assigned_case_dd_flagged) do
    create :assigned_case, :flagged_accepted,
           responding_team: responding_team_a,
           approving_team: team_dacu_disclosure
  end
  given(:assigned_case_team_b) { create :assigned_case,
                                        responding_team: responding_team_b }
  given(:case_with_response) { create :case_with_response,
                                      responder: responder_a }
  given(:responded_case) { create :responded_case, responder: responder_a }
  given(:closed_case) { create :closed_case, responder: responder_a }

  background do
    # Create our cases
    unassigned_case
    assigned_case_team_a
    assigned_case_coresponder_team_a
    assigned_case_dd_flagged
    assigned_case_team_b
    case_with_response
    responded_case
    closed_case
  end

  context 'for managers' do
    scenario 'shows all cases' do
      login_as create(:manager)
      visit '/cases/open?timeliness=in_time'
      cases = cases_page.case_list
      expect(cases.count).to eq 7

      expect(cases[0].number).to have_text unassigned_case.number
      expect(cases[1].number).to have_text assigned_case_team_a.number
      expect(cases[2].number).to have_text assigned_case_coresponder_team_a.number
      expect(cases[3].number).to have_text assigned_case_dd_flagged.number
      expect(cases[4].number).to have_text assigned_case_team_b.number
      expect(cases[5].number).to have_text case_with_response.number
      expect(cases[6].number).to have_text responded_case.number
    end
  end

  scenario 'for responder A on team A' do
    login_as responder_a
    visit '/cases/open?timeliness=in_time'

    cases = cases_page.case_list
    expect(cases.count).to eq 5
    expect(cases[0].number).to have_text assigned_case_team_a.number
    expect(cases[1].number).to have_text assigned_case_coresponder_team_a.number
    expect(cases[2].number).to have_text assigned_case_dd_flagged.number
    expect(cases[3].number).to have_text case_with_response.number
    expect(cases[4].number).to have_text responded_case.number
  end

  context 'for dacu disclosure' do
    scenario 'only shows their cases' do
      login_as disclosure_specialist

      visit '/cases/open?timeliness=in_time'

      cases = cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases[0].number).to have_text assigned_case_dd_flagged.number
    end
  end
end
