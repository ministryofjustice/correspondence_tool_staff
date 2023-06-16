require "rails_helper"

feature "listing open cases on the system" do
  background :all do
    @responding_team_a = create :responding_team,
                                name: "Responding Team A"
    @responding_team_b = create :responding_team,
                                name: "Responding Team B"
    @responder_a = create :responder,
                          full_name: "Responder A",
                          responding_teams: [@responding_team_a]
    @responder_b = create :responder,
                          full_name: "Responder B",
                          responding_teams: [@responding_team_b]
    @coresponder_a = create :responder,
                            full_name: "Co-Responder A",
                            responding_teams: [@responding_team_a]
    @team_dacu_disclosure = find_or_create :team_dacu_disclosure
    @disclosure_specialist = find_or_create :disclosure_specialist
    @disclosure_specialist_bmt = find_or_create :disclosure_specialist_bmt
    @press_officer = find_or_create :press_officer

    @unassigned_case = create :case
    @assigned_case_team_a = create :assigned_case,
                                   responding_team: @responding_team_a
    @assigned_case_coresponder_team_a = create :assigned_case,
                                               responder: @coresponder_a,
                                               responding_team: @responding_team_a

    @assigned_case_dd_flagged = create :assigned_case, :flagged_accepted,
                                       responding_team: @responding_team_a,
                                       approving_team: @team_dacu_disclosure

    @assigned_case_team_b = create :assigned_case,
                                   responding_team: @responding_team_b
    @assigned_case_late = create :assigned_case,
                                 received_date: 22.business_days.ago
    @assigned_case_flagged_for_press_office_accepted =
      create :assigned_case,
             :flagged,
             :press_office,
             created_at: 2.business_days.ago,
             identifier: "assigned_case_flagged_for_press_office_accepted"
    @closed_case = create :closed_case, responder: @responder_a
  end

  after(:all) { DbHousekeeping.clean }

  context "for managers" do
    scenario "shows all cases" do
      login_as create(:manager)
      visit "/cases/open"
      cases = cases_page.case_list
      expect(cases.count).to eq 7
      expect(cases[0].number).to have_text @assigned_case_late.number
      expect(cases[1].number).to have_text @assigned_case_team_a.number
      expect(cases[2].number).to have_text @assigned_case_coresponder_team_a.number
      expect(cases[3].number).to have_text @assigned_case_dd_flagged.number
      expect(cases[4].number).to have_text @assigned_case_team_b.number
      expect(cases[5].number).to have_text @assigned_case_flagged_for_press_office_accepted.number
      expect(cases[6].number).to have_text @unassigned_case.number
    end
  end

  scenario "for responder A on team A" do
    login_as @responder_a
    visit "/cases/open"

    cases = cases_page.case_list
    expect(cases.count).to eq 3
    expect(cases[0].number).to have_text @assigned_case_team_a.number
    expect(cases[1].number).to have_text @assigned_case_coresponder_team_a.number
    expect(cases[2].number).to have_text @assigned_case_dd_flagged.number
  end

  context "press officer" do
    scenario "only shows their cases" do
      login_as @press_officer

      visit "/cases/open"

      cases = cases_page.case_list
      expect(cases.count).to eq 1
      expect(cases[0].number)
        .to have_text @assigned_case_flagged_for_press_office_accepted.number
    end
  end

  context "disclosure specialist" do
    scenario "only shows their cases" do
      login_as @disclosure_specialist

      visit "/cases/open"

      cases = cases_page.case_list

      expect(cases.count).to eq 1
      expect(cases[0].number).to have_text @assigned_case_dd_flagged.number
    end
  end
end
