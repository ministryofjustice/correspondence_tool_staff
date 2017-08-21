require 'rails_helper'

module Stats
  describe R003BusinessUnitPerformanceReport do

    before(:all) do
      DbHousekeeping.clean
      Team.all.map(&:destroy)
      Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
        @bizgrp_ab = create :business_group, name: 'BGAB'
        @dir_a     = create :directorate, name: 'DRA', business_group: @bizgrp_ab
        @dir_b     = create :directorate, name: 'DRB', business_group: @bizgrp_ab
        @bizgrp_cd = create :business_group, name: 'BGCD'
        @dir_cd    = create :directorate, name: 'DRCD', business_group: @bizgrp_cd

        @team_a = create :business_unit, name: 'RTA', directorate: @dir_a
        @team_b = create :business_unit, name: 'RTB', directorate: @dir_b
        @team_c = create :business_unit, name: 'RTC', directorate: @dir_cd
        @team_d = create :business_unit, name: 'RTD', directorate: @dir_cd
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure
        @responder_a = create :responder, responding_teams: [@team_a]
        @responder_b = create :responder, responding_teams: [@team_b]
        @responder_c = create :responder, responding_teams: [@team_c]
        @responder_d = create :responder, responding_teams: [@team_d]

        @outcome = find_or_create :outcome, :granted

        # create cases based on today's date of 30/6/2017
        create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - responded late')
        create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - responded late')
        create_case(received: '20170605', responded: nil,        deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - open late')
        create_case(received: '20170605', responded: nil,        deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - open late')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_a, responder: @responder_a, ident: 'case for team a - open in time')
        create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_a, responder: @responder_a, ident: 'case for team a - responded in time')
        create_case(received: '20170605', responded: nil,        deadline: '20170625', team: @team_b, responder: @responder_b, ident: 'case for team b - open late')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_b, responder: @responder_b, ident: 'case for team b - open in time')
        create_case(received: '20170607', responded: '20170620', deadline: '20170625', team: @team_b, responder: @responder_b, ident: 'case for team b - responded in time')
        create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_c, responder: @responder_c, ident: 'case for team c - responded late')
        create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_c, responder: @responder_c, ident: 'case for team c - responded in time')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_d, responder: @responder_d, ident: 'case for team d - open in time')

        #flagged cases
        create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_a, responder: @responder_a, flagged: true, ident: 'case for team a - responded late')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_a, responder: @responder_a, flagged: true, ident: 'case for team a - open in time')
        create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_a, responder: @responder_a, flagged: true, ident: 'case for team a - responded in time')
        create_case(received: '20170605', responded: nil,        deadline: '20170625', team: @team_b, responder: @responder_b, flagged: true, ident: 'case for team b - open late')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_b, responder: @responder_b, flagged: true, ident: 'case for team b - open in time')
      end


      ###############
      # TODO Find a way not to create the extraneous teams in the first place
      ##############

      # delete extraneous teams
      Team.where('id > ?', @team_d.id).destroy_all
    end

    after(:all) do
      DbHousekeeping.clean
    end

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
      before do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          report = R003BusinessUnitPerformanceReport.new
          report.run
          @results = report.results
        end
      end

      it 'generates hierarchy starting with business_groups' do
        expect(@results.keys).to match_array [@bizgrp_ab, @bizgrp_cd]
      end

      it 'adds up directorate stats in each business_group' do
        expect(@results[@bizgrp_ab][:stats])
          .to eq({
                   non_trigger_responded_in_time: 2,
                   non_trigger_responded_late:    2,
                   non_trigger_open_in_time:      2,
                   non_trigger_open_late:         3,
                   trigger_responded_in_time:     1,
                   trigger_responded_late:        1,
                   trigger_open_in_time:          2,
                   trigger_open_late:             1
                 })
      end

      it 'generates hierarchy with directorates under business_groups' do
        expect(@results[@bizgrp_ab][:children].keys).to match_array [@dir_a, @dir_b]
      end

      it 'adds up business_unit stats in each directorate' do
        expect(@results[@bizgrp_cd][:children][@dir_cd][:stats])
          .to eq({
                   non_trigger_responded_in_time: 1,
                   non_trigger_responded_late:    1,
                   non_trigger_open_in_time:      1,
                   non_trigger_open_late:         0,
                   trigger_responded_in_time:     0,
                   trigger_responded_late:        0,
                   trigger_open_in_time:          0,
                   trigger_open_late:             0
                 })
      end

      it 'generates hierarchy with business_units under directorates' do
        expect(@results[@bizgrp_cd][:children][@dir_cd][:children].keys)
          .to match_array [@team_c, @team_d]
      end

      it 'adds up individual business_unit stats' do
        expect(@results[@bizgrp_cd][:children][@dir_cd][:children][@team_c][:stats])
          .to eq({
                   non_trigger_responded_in_time: 1,
                   non_trigger_responded_late:    1,
                   non_trigger_open_in_time:      0,
                   non_trigger_open_late:         0,
                   trigger_responded_in_time:     0,
                   trigger_responded_late:        0,
                   trigger_open_in_time:          0,
                   trigger_open_late:             0
                 })
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          expected_text = <<~EOCSV
            Business Unit Performance Report - 1 Jun 2017 to 30 Jun 2017
            "","","",Non-trigger FOIs,Non-trigger FOIs,Non-trigger FOIs,Non-trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs,Trigger FOIs
            Business Group,Directorate,Business Unit,Responded - in time,Responded - late,Open - in time,Open - late,Responded - in time,Responded - late,Open - in time,Open - late
            BGAB,"","",2,2,2,3,1,1,2,1
            BGAB,DRA,"",1,2,1,2,1,1,1,0
            BGAB,DRA,RTA,1,2,1,2,1,1,1,0
            BGAB,DRB,"",1,0,1,1,0,0,1,1
            BGAB,DRB,RTB,1,0,1,1,0,0,1,1
            BGCD,"","",1,1,1,0,0,0,0,0
            BGCD,DRCD,"",1,1,1,0,0,0,0,0
            BGCD,DRCD,RTC,1,1,0,0,0,0,0,0
            BGCD,DRCD,RTD,0,0,1,0,0,0,0,0
          EOCSV
          report = R003BusinessUnitPerformanceReport.new
          report.run
          expect(report.to_csv).to eq expected_text
        end
      end
    end

    # rubocop:disable Metrics/ParameterLists
    def create_case(received:, responded:, deadline:, team:, responder:, ident:, flagged: false)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create :case_with_response, responding_team: team, responder: responder, identifier: ident
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
