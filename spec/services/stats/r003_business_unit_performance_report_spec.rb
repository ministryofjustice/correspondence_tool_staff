require 'rails_helper'

# rubocop:disable Metrics/ModuleLength
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
        @info_held = find_or_create :info_status, :held

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
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_d, responder: @responder_d, ident: 'case for team d - open in time', type: 'irt')
        create_case(received: '20170605', responded: nil,        deadline: '20170702', team: @team_d, responder: @responder_d, ident: 'case for team d - open in time', type: 'irc')

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

    context 'defining the period' do
      context 'no period parameters passsed in' do
        it 'defaults from beginning of year to now' do
          Timecop.freeze(Time.local(2017, 12, 7, 12,33,44)) do
            report = R003BusinessUnitPerformanceReport.new
            expect(report.__send__(:reporting_period)).to eq '1 Jan 2017 to 7 Dec 2017'
          end
        end
      end

      context 'period params are passed in' do
        it 'uses the specify period' do
          d1 = Date.new(2017, 6, 1)
          d2 = Date.new(2017, 6, 30)
          report = R003BusinessUnitPerformanceReport.new(d1, d2)
          expect(report.__send__(:reporting_period)).to eq '1 Jun 2017 to 30 Jun 2017'
        end
      end
    end

    describe '#title' do
      it 'returns the report title' do
        expect(R003BusinessUnitPerformanceReport.title).to eq 'Business unit report (FOIs)'
      end
    end

    describe '#description' do
      it 'returns the report description' do
        expect(R003BusinessUnitPerformanceReport.description).to eq 'Shows all FOI open cases and cases closed this month, in-time or late, by responding team'
      end
    end


    context 'without business unit columns' do
      describe '#results' do
        before do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            report = R003BusinessUnitPerformanceReport.new
            report.run
            @results = report.results
          end
        end

        it 'adds up directorate stats in each business_group' do
          expect(@results[@bizgrp_ab.id])
              .to eq({
                         business_group:                @bizgrp_ab.name,
                         directorate:                   '',
                         business_unit:                 '',
                         responsible:                   @bizgrp_ab.team_lead,
                         non_trigger_performance:       28.6,
                         non_trigger_total:             9,
                         non_trigger_responded_in_time: 2,
                         non_trigger_responded_late:    2,
                         non_trigger_open_in_time:      2,
                         non_trigger_open_late:         3,
                         trigger_performance:           33.3,
                         trigger_total:                 5,
                         trigger_responded_in_time:     1,
                         trigger_responded_late:        1,
                         trigger_open_in_time:          2,
                         trigger_open_late:             1,
                         overall_performance:           30.0,
                         overall_total:                 14,
                         overall_responded_in_time:     3,
                         overall_responded_late:        3,
                         overall_open_in_time:          4,
                         overall_open_late:             4
                     })
        end

        it 'adds up business_unit stats in each directorate' do
          expect(@results[@bizgrp_cd.id])
              .to eq({
                         business_group:                @bizgrp_cd.name,
                         directorate:                   '',
                         business_unit:                 '',
                         responsible:                   @bizgrp_cd.team_lead,
                         non_trigger_performance:       50.0,
                         non_trigger_total:             3,
                         non_trigger_responded_in_time: 1,
                         non_trigger_responded_late:    1,
                         non_trigger_open_in_time:      1,
                         non_trigger_open_late:         0,
                         trigger_performance:           0.0,
                         trigger_total:                 0,
                         trigger_responded_in_time:     0,
                         trigger_responded_late:        0,
                         trigger_open_in_time:          0,
                         trigger_open_late:             0,
                         overall_performance:           50.0,
                         overall_total:                 3,
                         overall_responded_in_time:     1,
                         overall_responded_late:        1,
                         overall_open_in_time:          1,
                         overall_open_late:             0
                     })
        end

        it 'adds up individual business_unit stats' do
          expect(@results[@team_c.id])
              .to eq({
                         business_group:                @bizgrp_cd.name,
                         directorate:                   @dir_cd.name,
                         business_unit:                 @team_c.name,
                         responsible:                   @team_c.team_lead,
                         non_trigger_performance:       50.0,
                         non_trigger_total:             2,
                         non_trigger_responded_in_time: 1,
                         non_trigger_responded_late:    1,
                         non_trigger_open_in_time:      0,
                         non_trigger_open_late:         0,
                         trigger_performance:           0.0,
                         trigger_total:                 0,
                         trigger_responded_in_time:     0,
                         trigger_responded_late:        0,
                         trigger_open_in_time:          0,
                         trigger_open_late:             0,
                         overall_performance:           50.0,
                         overall_total:                 2,
                         overall_responded_in_time:     1,
                         overall_responded_late:        1,
                         overall_open_in_time:          0,
                         overall_open_late:             0
                     })
        end
      end

      describe '#to_csv' do
        it 'outputs results as a csv lines' do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            super_header = %q{"","","","",} +
                %q{Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,} +
                %q{Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,} +
                %q{Overall,Overall,Overall,Overall,Overall,Overall}
            header = %q{Business group,Directorate,Business unit,Responsible,} +
                %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late,} +
                %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late,} +
                %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late}
            expected_text = <<~EOCSV
            Business unit report (FOIs) - 1 Jan 2017 to 30 Jun 2017
            #{super_header}
            #{header}
            BGAB,"","",#{@bizgrp_ab.team_lead},28.6,9,2,2,2,3,33.3,5,1,1,2,1,30.0,14,3,3,4,4
            BGAB,DRA,"",#{@dir_a.team_lead},20.0,6,1,2,1,2,50.0,3,1,1,1,0,28.6,9,2,3,2,2
            BGAB,DRA,RTA,#{@team_a.team_lead},20.0,6,1,2,1,2,50.0,3,1,1,1,0,28.6,9,2,3,2,2
            BGAB,DRB,"",#{@dir_b.team_lead},50.0,3,1,0,1,1,0.0,2,0,0,1,1,33.3,5,1,0,2,2
            BGAB,DRB,RTB,#{@team_b.team_lead},50.0,3,1,0,1,1,0.0,2,0,0,1,1,33.3,5,1,0,2,2
            BGCD,"","",#{@bizgrp_cd.team_lead},50.0,3,1,1,1,0,0.0,0,0,0,0,0,50.0,3,1,1,1,0
            BGCD,DRCD,"",#{@dir_cd.team_lead},50.0,3,1,1,1,0,0.0,0,0,0,0,0,50.0,3,1,1,1,0
            BGCD,DRCD,RTC,#{@team_c.team_lead},50.0,2,1,1,0,0,0.0,0,0,0,0,0,50.0,2,1,1,0,0
            BGCD,DRCD,RTD,#{@team_d.team_lead},0.0,1,0,0,1,0,0.0,0,0,0,0,0,0.0,1,0,0,1,0
            Total,"","","",33.3,12,3,3,3,3,33.3,5,1,1,2,1,33.3,17,4,4,5,4
            EOCSV
            report = R003BusinessUnitPerformanceReport.new
            report.run
            actual_lines = report.to_csv.split("\n")
            expected_lines = expected_text.split("\n")

            (0...actual_lines.size).each do |i|
              expect(actual_lines[i]).to eq expected_lines[i]
            end
          end
        end
      end


      context 'with a case in the db that is unassigned' do
        before do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            create :case, identifier: 'unassigned case'
          end
        end

        it 'does not raise an error' do
          report = R003BusinessUnitPerformanceReport.new
          expect { report.run }.not_to raise_error
        end
      end
    end


    context 'with business unit columns' do
      describe '#results' do
        before do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            # report = R003BusinessUnitPerformanceReport.new
            report = R003BusinessUnitPerformanceReport.new(Time.now.beginning_of_year, Time.now, true)
            report.run
            @results = report.results
          end
        end

        it 'generates hierarchy starting with business_groups' do
          expect(@results.keys).to eq Team.hierarchy.map(&:id) + [:total]
        end

        it 'adds up directorate stats in each business_group' do
          expect(@results[@bizgrp_ab.id])
            .to eq({
                     business_group:                @bizgrp_ab.name,
                     directorate:                   '',
                     business_unit:                 '',
                     responsible:                   @bizgrp_ab.team_lead,
                     non_trigger_performance:       28.6,
                     non_trigger_total:             9,
                     non_trigger_responded_in_time: 2,
                     non_trigger_responded_late:    2,
                     non_trigger_open_in_time:      2,
                     non_trigger_open_late:         3,
                     trigger_performance:           33.3,
                     trigger_total:                 5,
                     trigger_responded_in_time:     1,
                     trigger_responded_late:        1,
                     trigger_open_in_time:          2,
                     trigger_open_late:             1,
                     overall_performance:           30.0,
                     overall_total:                 14,
                     overall_responded_in_time:     3,
                     overall_responded_late:        3,
                     overall_open_in_time:          4,
                     overall_open_late:             4,
                     bu_performance:                0.0,
                     bu_total:                      14,
                     bu_responded_in_time:          0,
                     bu_responded_late:             6,
                     bu_open_in_time:               0,
                     bu_open_late:                  8
                   })
        end

        it 'adds up business_unit stats in each directorate' do
          expect(@results[@bizgrp_cd.id])
            .to eq({
                     business_group:                @bizgrp_cd.name,
                     directorate:                   '',
                     business_unit:                 '',
                     responsible:                   @bizgrp_cd.team_lead,
                     non_trigger_performance:       50.0,
                     non_trigger_total:             3,
                     non_trigger_responded_in_time: 1,
                     non_trigger_responded_late:    1,
                     non_trigger_open_in_time:      1,
                     non_trigger_open_late:         0,
                     trigger_performance:           0.0,
                     trigger_total:                 0,
                     trigger_responded_in_time:     0,
                     trigger_responded_late:        0,
                     trigger_open_in_time:          0,
                     trigger_open_late:             0,
                     overall_performance:           50.0,
                     overall_total:                 3,
                     overall_responded_in_time:     1,
                     overall_responded_late:        1,
                     overall_open_in_time:          1,
                     overall_open_late:             0,
                     bu_performance:                0.0,
                     bu_total:                      3,
                     bu_responded_in_time:          0,
                     bu_responded_late:             2,
                     bu_open_in_time:               0,
                     bu_open_late:                  1
                   })
        end

        it 'adds up individual business_unit stats' do
          expect(@results[@team_c.id])
            .to eq({
                     business_group:                @bizgrp_cd.name,
                     directorate:                   @dir_cd.name,
                     business_unit:                 @team_c.name,
                     responsible:                   @team_c.team_lead,
                     non_trigger_performance:       50.0,
                     non_trigger_total:             2,
                     non_trigger_responded_in_time: 1,
                     non_trigger_responded_late:    1,
                     non_trigger_open_in_time:      0,
                     non_trigger_open_late:         0,
                     trigger_performance:           0.0,
                     trigger_total:                 0,
                     trigger_responded_in_time:     0,
                     trigger_responded_late:        0,
                     trigger_open_in_time:          0,
                     trigger_open_late:             0,
                     overall_performance:           50.0,
                     overall_total:                 2,
                     overall_responded_in_time:     1,
                     overall_responded_late:        1,
                     overall_open_in_time:          0,
                     overall_open_late:             0,
                     bu_performance:                0.0,
                     bu_total:                      2,
                     bu_responded_in_time:          0,
                     bu_responded_late:             2,
                     bu_open_in_time:               0,
                     bu_open_late:                  0
                   })
        end
      end

      describe '#to_csv' do
        it 'outputs results as a csv lines' do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            super_header = %q{"","","","",} +
              %q{Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,} +
              %q{Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,} +
              %q{Overall,Overall,Overall,Overall,Overall,Overall,} +
              %q{Business unit,Business unit,Business unit,Business unit,Business unit,Business unit}
            header = %q{Business group,Directorate,Business unit,Responsible,} +
              %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late,} +
              %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late,} +
              %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late,} +
              %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late}
            expected_text = <<~EOCSV
              Business unit report (FOIs) - 1 Jan 2017 to 30 Jun 2017
              #{super_header}
              #{header}
              BGAB,"","",#{@bizgrp_ab.team_lead},28.6,9,2,2,2,3,33.3,5,1,1,2,1,30.0,14,3,3,4,4,0.0,14,0,6,0,8
              BGAB,DRA,"",#{@dir_a.team_lead},20.0,6,1,2,1,2,50.0,3,1,1,1,0,28.6,9,2,3,2,2,0.0,9,0,5,0,4
              BGAB,DRA,RTA,#{@team_a.team_lead},20.0,6,1,2,1,2,50.0,3,1,1,1,0,28.6,9,2,3,2,2,0.0,9,0,5,0,4
              BGAB,DRB,"",#{@dir_b.team_lead},50.0,3,1,0,1,1,0.0,2,0,0,1,1,33.3,5,1,0,2,2,0.0,5,0,1,0,4
              BGAB,DRB,RTB,#{@team_b.team_lead},50.0,3,1,0,1,1,0.0,2,0,0,1,1,33.3,5,1,0,2,2,0.0,5,0,1,0,4
              BGCD,"","",#{@bizgrp_cd.team_lead},50.0,3,1,1,1,0,0.0,0,0,0,0,0,50.0,3,1,1,1,0,0.0,3,0,2,0,1
              BGCD,DRCD,"",#{@dir_cd.team_lead},50.0,3,1,1,1,0,0.0,0,0,0,0,0,50.0,3,1,1,1,0,0.0,3,0,2,0,1
              BGCD,DRCD,RTC,#{@team_c.team_lead},50.0,2,1,1,0,0,0.0,0,0,0,0,0,50.0,2,1,1,0,0,0.0,2,0,2,0,0
              BGCD,DRCD,RTD,#{@team_d.team_lead},0.0,1,0,0,1,0,0.0,0,0,0,0,0,0.0,1,0,0,1,0,0.0,1,0,0,0,1
              Total,"","","",33.3,12,3,3,3,3,33.3,5,1,1,2,1,33.3,17,4,4,5,4,0.0,17,0,8,0,9
            EOCSV
            report = R003BusinessUnitPerformanceReport.new(Time.now.beginning_of_year, Time.now, true)
            report.run
            actual_lines = report.to_csv.split("\n")
            expected_lines = expected_text.split("\n")

            (0...actual_lines.size).each do |i|
              expect(actual_lines[i]).to eq expected_lines[i]
            end
          end
        end
      end


      context 'with a case in the db that is unassigned' do
        before do
          Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
            create :case, identifier: 'unassigned case'
          end
        end

        it 'does not raise an error' do
          report = R003BusinessUnitPerformanceReport.new
          expect { report.run }.not_to raise_error
        end
      end
    end


    # rubocop:disable Metrics/ParameterLists
    # rubocop:disable Metrics/CyclomaticComplexity
    def create_case(received:, responded:, deadline:, team:, responder:, ident:, flagged: false, type: 'std')
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        factory = case type
                    when 'std'
                      :case_with_response
                    when 'irt'
                      :accepted_timeliness_review
                    when 'irc'
                      :accepted_compliance_review
                  end


        kase = create factory, responding_team: team, responder: responder, identifier: ident
        kase.external_deadline = Date.parse(deadline)
        if flagged == true
          CaseFlagForClearanceService.new(user: kase.managing_team.users.first, kase: kase, team: @team_dacu_disclosure).call
        end
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.state_machine.respond!(acting_user: responder, acting_team: team)
            kase.update!(date_responded: Time.now, outcome_id: @outcome.id, info_held_status: @info_held)
            kase.state_machine.close!(acting_user: kase.managing_team.users.first, acting_team: kase.managing_team)
          end
        end
      end
      kase.save!
      kase
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/CyclomaticComplexity

  end

end
# rubocop:enable Metrics/ModuleLength
