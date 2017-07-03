require 'rails_helper'

module Stats
  describe R001RespondedCaseTimelinessReport do

    before(:all) do
      @team_1 = create :team, name: 'RTA'
      @team_2 = create :team, name: 'RTB'
      create_case(received: '20170531', responded: '20170629', deadline: '20170625', team: @team_1)   # received last month - not included
      create_case(received: '20170601', responded: '20170629', deadline: '20170625', team: @team_1)   # team 1 overdue
      create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_1)   # team 1 overdue
      create_case(received: '20170604', responded: nil, deadline: '20170625', team: @team_1)          # team 1 - not responded
      create_case(received: '20170604', responded: '20170629', deadline: '20170630', team: @team_1)   # team 1 - in time
      create_case(received: '20170601', responded: '20170620', deadline: '20170625', team: @team_2)   # team 2 - in time
      Timecop.freeze Time.new(2017, 6, 30, 12, 1, 2)
    end

    after(:all)  do
      Timecop.return
      DbHousekeeping.clean
    end

    describe '#results' do
      it 'generates_stats as a hash of hashes' do
        report = R001RespondedCaseTimelinessReport.new
        report.run
        expect(report.results).to eq( { 'RTA' => {'In time' => 1, 'Overdue' => 2}, 'RTB' => {'In time' => 1} } )
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        expected_text = "Team,In time,Overdue\nRTA,1,2\nRTB,1,0\n"
        report = R001RespondedCaseTimelinessReport.new
        report.run
        expect(report.to_csv).to eq expected_text
      end
    end


    def create_case(received:, responded:, deadline:, team:)
      kase =  if responded.nil?
                create :awaiting_responder_case, received_date: Date.parse(received), responding_team: team
              else
                create :responded_case, received_date: Date.parse(received), responding_team: team
              end
      kase.date_responded = Date.parse(responded) unless responded.nil?
      kase.external_deadline = Date.parse(deadline)
      kase.save!
    end



  end
end
