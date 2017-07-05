require 'rails_helper'

module Stats
  describe R002OpenFoiCasesByTeamReport do

    it 'produces the right figures' do
      setup_teams_and_cases
      report = R002OpenFoiCasesByTeamReport.new
      report.run
      expect(report.to_csv).to eq expected_output
    end


    def setup_teams_and_cases
      team_dacu = create :team_dacu
      team_dacu_disclosure = create :team_dacu_disclosure
      team_a = create :responding_team, name: "My responding team A"
      team_b = create :responding_team, name: "My responding team B"

      # 1 unassigned - with dacu
      create :case

      # 2 awaiting responder - with responding team a
      # 1 awaiting responder - with responding team b
      2.times { create :awaiting_responder_case, responding_team: team_a }
      create :awaiting_responder_case, responding_team: team_b

      # 2 drafting with responding team a
      # 1 drafting with responding team  b
      2.times { create :case_being_drafted, responding_team: team_a }
      create :case_being_drafted, responding_team: team_b

      # 1 awaiting dispatch state - with team a
      create :case_with_response, responding_team: team_a

      # 2 pending dacu clearance state - with dacu disclosure
      2.times { create :pending_dacu_clearance_case }

      # 1 responded case - outside scope of report
      create :responded_case

      # 2 closed case - outside scope of report
      2.times { create :closed_case }

      Team.all.each do |t|
        t.destroy unless t.in?([team_dacu, team_dacu_disclosure, team_a, team_b])
      end
    end

    def expected_output
      "Team,No. of cases\n" +
      "DACU,1\n" +
      "DACU Disclosure,2\n" +
      "My responding team A,5\n" +
      "My responding team B,2\n"
    end

  end
end
