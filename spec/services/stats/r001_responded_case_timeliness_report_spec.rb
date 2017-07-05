require 'rails_helper'

module Stats
  describe R001RespondedCaseTimelinessReport do

    before(:all) do
      Team.all.map(&:destroy)
      @team_1 = create :team, name: 'RTA'
      @team_2 = create :team, name: 'RTB'
      @responder_1 = create :responder, responding_teams: [@team_1]
      @responder_2 = create :responder, responding_teams: [@team_2]
      create_case(received: '20170525', responded: '20170531', deadline: '20170625', team: @team_1, responder: @responder_1)   # received last month - not included
      create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_1, responder: @responder_1)   # team 1 overdue
      create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_1, responder: @responder_1)   # team 1 overdue
      create_case(received: '20170605', responded: nil, deadline: '20170625', team: @team_1, responder: @responder_1)          # team 1 - not responded
      create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_1, responder: @responder_1)   # team 1 - in time
      create_case(received: '20170607', responded: '20170620', deadline: '20170625', team: @team_2, responder: @responder_2)   # team 2 - in time
      Team.where.not(id: [@team_1.id, @team_2.id]).map(&:destroy)
    end

    after(:all)  { DbHousekeeping.clean }

    describe '#results' do
      it 'generates_stats as a hash of hashes' do
        Timecop.freeze Date.new(2017, 6, 30) do
          report = R001RespondedCaseTimelinessReport.new
          report.run
          expect(report.results).to eq( { 'RTA' => {'In time' => 1, 'Overdue' => 2}, 'RTB' => {'In time' => 1, 'Overdue' => 0} } )
        end
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        Timecop.freeze Date.new(2017, 6, 30) do
          expected_text = "Team,In time,Overdue\nRTA,1,2\nRTB,1,0\n"
          report = R001RespondedCaseTimelinessReport.new
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
