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
  given(:disclosure_specialist_bmt) { create :disclosure_specialist_bmt }
  given(:press_officer) { create :press_officer }

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
  given(:assigned_case_flagged_for_press_office_accepted) do
    create :assigned_case,
           :flagged_accepted,
           :press_office,
           created_at: 2.business_days.ago,
           disclosure_assignment_state: 'pending',
           identifier: 'assigned_case_flagged_for_press_office_accepted'
  end
  given(:assigned_case_team_b) { create :assigned_case,
                                        responding_team: responding_team_b }
  given(:assigned_case_late) { create :assigned_case,
                                      received_date: 22.business_days.ago }
  given(:closed_case) { create :closed_case, responder: responder_a }

  background do
    # Create our cases
    unassigned_case
    assigned_case_team_a
    assigned_case_coresponder_team_a
    assigned_case_dd_flagged
    assigned_case_team_b
    assigned_case_late
    assigned_case_flagged_for_press_office_accepted
    closed_case
  end

  context 'for managers' do
    scenario 'shows all cases' do
      login_as create(:manager)
      visit '/cases/open/in_time'
      cases = cases_page.case_list
      expect(cases.count).to eq 6
      expect(cases[0].number).to have_text assigned_case_team_a.number
      expect(cases[1].number).to have_text assigned_case_coresponder_team_a.number
      expect(cases[2].number).to have_text assigned_case_dd_flagged.number
      expect(cases[3].number).to have_text assigned_case_team_b.number
      expect(cases[4].number).to have_text assigned_case_flagged_for_press_office_accepted.number
      expect(cases[5].number).to have_text unassigned_case.number
    end
  end

  scenario 'for responder A on team A' do
    login_as responder_a
    visit '/cases/open/in_time'

    cases = cases_page.case_list
    expect(cases.count).to eq 3
    expect(cases[0].number).to have_text assigned_case_team_a.number
    expect(cases[1].number).to have_text assigned_case_coresponder_team_a.number
    expect(cases[2].number).to have_text assigned_case_dd_flagged.number
  end

  context 'press officer' do
    scenario 'only shows their cases' do
      login_as press_officer

      visit '/cases/open/in_time'

      cases = cases_page.case_list
      expect(cases.count).to eq 1
      expect(cases[0].number)
        .to have_text assigned_case_flagged_for_press_office_accepted.number
    end
  end

  context 'disclosure specialist' do
    scenario 'only shows their cases' do
      login_as disclosure_specialist

      visit '/cases/open/in_time'

      cases = cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases[0].number).to have_text assigned_case_dd_flagged.number
    end
  end

  context 'disclosure specialist / bmt' do
    scenario 'only shows their cases' do
      login_as disclosure_specialist_bmt

      visit '/cases/open/in_time'

      cases = cases_page.case_list

      expect(cases.count).to eq 6
      expect(cases[0].number).to have_text assigned_case_team_a.number
      expect(cases[1].number).to have_text assigned_case_coresponder_team_a.number
      expect(cases[2].number).to have_text assigned_case_dd_flagged.number
      expect(cases[3].number).to have_text assigned_case_team_b.number
      expect(cases[4].number).to have_text assigned_case_flagged_for_press_office_accepted.number
      expect(cases[5].number).to have_text unassigned_case.number
    end
  end
end
