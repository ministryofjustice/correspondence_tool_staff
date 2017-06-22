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

  given(:assigned_case) { create :assigned_case, identifier: 'assigned_case' }
  given(:assigned_case_late_team_a) do
    create :assigned_case,
           received_date: 22.business_days.ago,
           responding_team: responding_team_a,
           identifier: 'assigned_case_late_team_a'
  end
  given(:assigned_case_late_coresponder_team_a) do
    create :assigned_case,
           received_date: 22.business_days.ago,
           responder: coresponder_a,
           responding_team: responding_team_a,
           identifier: 'assigned_case_late_coresponder_team_a'
  end
  given(:assigned_case_late_dd_flagged_team_a) do
    create :assigned_case, :flagged_accepted,
           received_date: 22.business_days.ago,
           responding_team: responding_team_a,
           approving_team: team_dacu_disclosure,
           identifier: 'assigned_case_late_dd_flagged_team_a'
  end
  given(:assigned_case_late_team_b) do
    create :assigned_case,
           received_date: 22.business_days.ago,
           responding_team: responding_team_b,
           identifier: 'assigned_case_late_team_b'
  end

  background do
    # Create our cases
    assigned_case
    assigned_case_late_team_a
    assigned_case_late_team_b
    assigned_case_late_coresponder_team_a
    assigned_case_late_dd_flagged_team_a
  end

  context 'for managers' do
    scenario 'shows all cases' do
      login_as create(:manager)
      visit '/cases/open?timeliness=late'
      cases = cases_page.case_list
      expect(cases.count).to eq 4

      expect(cases[0].number).to have_text assigned_case_late_team_a.number
      expect(cases[1].number).to have_text assigned_case_late_team_b.number
      expect(cases[2].number)
        .to have_text assigned_case_late_coresponder_team_a.number
      expect(cases[3].number)
        .to have_text assigned_case_late_dd_flagged_team_a.number
    end
  end

  scenario 'for responder A on team A' do
    login_as responder_a
    visit '/cases/open?timeliness=late'

    cases = cases_page.case_list
    expect(cases.count).to eq 3
    expect(cases[0].number).to have_text assigned_case_late_team_a.number
    expect(cases[1].number)
      .to have_text assigned_case_late_coresponder_team_a.number
    expect(cases[2].number)
      .to have_text assigned_case_late_dd_flagged_team_a.number
  end

  context 'approvers' do
    scenario 'only shows their cases' do
      login_as disclosure_specialist

      visit '/cases/open?timeliness=late'

      cases = cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases[0].number)
        .to have_text assigned_case_late_dd_flagged_team_a.number
    end
  end
end
