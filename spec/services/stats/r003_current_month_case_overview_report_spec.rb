require 'rails_helper'

module Stats
  describe R003CurrentMonthCaseOverviewReport do

    before(:all) do
      Team.all.map(&:destroy)
      @team_1 = create :team, name: 'RTA'
      @team_2 = create :team, name: 'RTB'
      @responder_1 = create :responder, responding_teams: [@team_1]
      @responder_2 = create :responder, responding_teams: [@team_2]

      # create cases based on today's date of 30/6/2017
      create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_1, responder: @responder_1)   # team 1 - responded late
      create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_1, responder: @responder_1)   # team 1 - responded late
      create_case(received: '20170605', responded: nil, deadline: '20170625', team: @team_1, responder: @responder_1)          # team 1 - open late
      create_case(received: '20170605', responded: nil, deadline: '20170625', team: @team_1, responder: @responder_1)          # team 1 - open late
      create_case(received: '20170605', responded: nil, deadline: '20170702', team: @team_1, responder: @responder_1)          # team 1 - open in time
      create_case(received: '20170605', responded: nil, deadline: '20170625', team: @team_2, responder: @responder_1)          # team 2 - open late
      create_case(received: '20170605', responded: nil, deadline: '20170702', team: @team_2, responder: @responder_1)          # team 2 - open in time
      create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_1, responder: @responder_1)   # team 1 - responded in time
      create_case(received: '20170607', responded: '20170620', deadline: '20170625', team: @team_2, responder: @responder_2)   # team 2 - responded in time
      Team.where.not(id: [@team_1.id, @team_2.id]).map(&:destroy)
    end

    after(:all)  { DbHousekeeping.clean }

    describe '#title' do
      it 'returns the report title' do
        expect(R003CurrentMonthCaseOverviewReport.title).to eq 'Current Month Case Overview Report'
      end
    end

    describe '#description' do
      it 'returns the report description' do
        expect(R003CurrentMonthCaseOverviewReport.description).to eq 'Shows all open cases and cases responded this month, in-time or late, by responding team'
      end
    end

    describe '#results' do
      it 'generates_stats as a hash of hashes' do
        Timecop.freeze Date.new(2017, 6, 30) do
          report = R003CurrentMonthCaseOverviewReport.new
          report.run
          expect(report.results).to eq(
                                      {'RTA' => {
                                        'Responded - in time'   => 1,
                                        'Responded - late'      => 2,
                                        'Open - in time'        => 1,
                                        'Open - late'           => 2},
                                       'RTB' => {
                                         'Responded - in time'  => 1,
                                         'Responded - late'     => 0,
                                         'Open - in time'       => 1,
                                         'Open - late'          => 1
                                       }
                                      } )
        end
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        Timecop.freeze Date.new(2017, 6, 30) do
          expected_text = "Teams,Responded - in time,Responded - late,Open - in time,Open - late\n" +
                          "RTA,1,2,1,2\n" +
                          "RTB,1,0,1,1\n"
          report = R003CurrentMonthCaseOverviewReport.new
          report.run
          expect(report.to_csv).to eq expected_text
        end
      end
    end


    def create_case(received:, responded:, deadline:, team:, responder:)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create :case_with_response, responding_team: team
        kase.external_deadline = Date.parse(deadline)
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.state_machine.respond!(responder, team)
          end
        end
      end
      kase.save!
    end



  end
end
