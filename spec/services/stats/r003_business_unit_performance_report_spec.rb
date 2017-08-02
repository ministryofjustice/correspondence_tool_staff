require 'rails_helper'

module Stats
  describe R003BusinessUnitPerformanceReport do

    before(:all) do
      DbHousekeeping.clean
      Team.all.map(&:destroy)
      @team_1 = create :business_unit, name: 'RTA'
      @team_2 = create :business_unit, name: 'RTB'
      @team_dacu_disclosure = find_or_create :team_dacu_disclosure
      @responder_1 = create :responder, responding_teams: [@team_1]
      @responder_2 = create :responder, responding_teams: [@team_2]

      @outcome = find_or_create :outcome, :granted
      
      Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
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

        #flagged cases
        create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_1, responder: @responder_1, flagged: true)   # team 1 - responded late
        create_case(received: '20170605', responded: nil, deadline: '20170702', team: @team_1, responder: @responder_1, flagged: true)          # team 1 - open in time
        create_case(received: '20170605', responded: nil, deadline: '20170625', team: @team_2, responder: @responder_1, flagged: true)          # team 2 - open late
        create_case(received: '20170605', responded: nil, deadline: '20170702', team: @team_2, responder: @responder_1, flagged: true)          # team 2 - open in time
        create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_1, responder: @responder_1, flagged: true)   # team 1 - responded in time
      end
    end

    after(:all)  { DbHousekeeping.clean }

    describe '#title' do
      it 'returns the report title' do
        expect(R003BusinessUnitPerformanceReport.title).to eq 'Business Unit Performance Report'
      end
    end

    describe '#description' do
      it 'returns the report description' do
        expect(R003BusinessUnitPerformanceReport.description).to eq 'Shows all open cases and cases closed this month, in-time or late, by responding team'
      end
    end

    describe '#results' do
      it 'generates_stats as a hash of hashes' do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          report = R003BusinessUnitPerformanceReport.new
          report.run
          expect(report.results).to eq(
                                      {'RTA' => {
                                        :non_trigger_responded_in_time  => 1,
                                        :non_trigger_responded_late     => 2,
                                        :non_trigger_open_in_time       => 1,
                                        :non_trigger_open_late          => 2,
                                        :trigger_responded_in_time      => 1,
                                        :trigger_responded_late         => 1,
                                        :trigger_open_in_time           => 1,
                                        :trigger_open_late              => 0},
                                       'RTB' => {
                                         :non_trigger_responded_in_time  => 1,
                                         :non_trigger_responded_late     => 0,
                                         :non_trigger_open_in_time       => 1,
                                         :non_trigger_open_late          => 1,
                                         :trigger_responded_in_time      => 0,
                                         :trigger_responded_late         => 0,
                                         :trigger_open_in_time           => 1,
                                         :trigger_open_late              => 1}
                                      } )
        end
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          expected_text = %Q{Business Unit Performance Report - 1 Jun 2017 to 30 Jun 2017\n} +
                          %Q{"",Non-trigger FOIs,Non-trigger FOIs,Non-trigger FOIs,Non-trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs\n} +
                          %Q{Teams,Responded - in time,Responded - late,Open - in time,Open - late,Responded - in time,Responded - late,Open - in time,Open - late\n} +
                          %Q{RTA,1,2,1,2,1,1,1,0\n} +
                          %Q{RTB,1,0,1,1,0,0,1,1\n}
          report = R003BusinessUnitPerformanceReport.new
          report.run
          expect(report.to_csv).to eq expected_text
        end
      end
    end

    # rubocop:disable Metrics/ParameterLists
    def create_case(received:, responded:, deadline:, team:, responder:, flagged: false)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create :case_with_response, responding_team: team, responder: responder
        kase.external_deadline = Date.parse(deadline)
        if flagged == true
          CaseFlagForClearanceService.new(user: kase.managing_team.users.first, kase: kase, team: @team_dacu_disclosure).call
        end
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.state_machine.respond!(responder, team)
            kase.update!(date_responded: Time.now, outcome_id: @outcome.id)
            kase.state_machine.close!(kase.managing_team.users.first, kase.managing_team)
          end
        end
      end
      kase.save!
      kase
    end
    # rubocop:enable Metrics/ParameterLists


  end
end
