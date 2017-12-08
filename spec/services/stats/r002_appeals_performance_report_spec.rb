require 'rails_helper'

module Stats
  describe R002AppealsPerformanceReport do

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
        create_appeal(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - responded late')
        create_appeal(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - responded late')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - open late')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170625', team: @team_a, responder: @responder_a, ident: 'case for team a - open late')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170702', team: @team_a, responder: @responder_a, ident: 'case for team a - open in time')
        create_appeal(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_a, responder: @responder_a, ident: 'case for team a - responded in time')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170625', team: @team_b, responder: @responder_b, ident: 'case for team b - open late')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170702', team: @team_b, responder: @responder_b, ident: 'case for team b - open in time')
        create_appeal(received: '20170607', responded: '20170620', deadline: '20170625', team: @team_b, responder: @responder_b, ident: 'case for team b - responded in time')
        create_appeal(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_c, responder: @responder_c, ident: 'case for team c - responded late')
        create_appeal(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_c, responder: @responder_c, ident: 'case for team c - responded in time')
        create_appeal(received: '20170605', responded: nil,        deadline: '20170702', team: @team_d, responder: @responder_d, ident: 'case for team d - open in time')
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
        expect(R002AppealsPerformanceReport.title).to eq 'Appeal performance stats'
      end
    end

    describe '#description' do
      it 'returns the report description' do
        expect(R002AppealsPerformanceReport.description).to eq 'Shows all open appeals and appeals closed this month, in-time or late, by responding team'
      end
    end

    describe '#results' do
      before do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          # report = R002AppealsPerformanceReport.new
          report = R002AppealsPerformanceReport.new
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
                   appeal_performance:       28.6,
                   appeal_total:             9,
                   appeal_responded_in_time: 2,
                   appeal_responded_late:    2,
                   appeal_open_in_time:      2,
                   appeal_open_late:         3,
                 })
      end

      it 'adds up business_unit stats in each directorate' do
        expect(@results[@bizgrp_cd.id])
          .to eq({
                   business_group:                @bizgrp_cd.name,
                   directorate:                   '',
                   business_unit:                 '',
                   responsible:                   @bizgrp_cd.team_lead,
                   appeal_performance:       50.0,
                   appeal_total:             3,
                   appeal_responded_in_time: 1,
                   appeal_responded_late:    1,
                   appeal_open_in_time:      1,
                   appeal_open_late:         0,
                 })
      end

      it 'adds up individual business_unit stats' do
        expect(@results[@team_c.id])
          .to eq({
                   business_group:                @bizgrp_cd.name,
                   directorate:                   @dir_cd.name,
                   business_unit:                 @team_c.name,
                   responsible:                   @team_c.team_lead,
                   appeal_performance:       50.0,
                   appeal_total:             2,
                   appeal_responded_in_time: 1,
                   appeal_responded_late:    1,
                   appeal_open_in_time:      0,
                   appeal_open_late:         0,
                 })
      end
    end

    describe '#to_csv' do
      it 'outputs results as a csv lines' do
        Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do
          super_header = %q{"","","","",} +
            %q{Internal reviews,Internal reviews,Internal reviews,Internal reviews,Internal reviews,Internal reviews}
          header = %q{Business group,Directorate,Business unit,Responsible,} +
            %q{Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late}
          expected_text = <<~EOCSV
            Appeal performance stats - 1 Jan 2017 to 30 Jun 2017
            #{super_header}
            #{header}
            BGAB,"","",#{@bizgrp_ab.team_lead},28.6,9,2,2,2,3
            BGAB,DRA,"",#{@dir_a.team_lead},20.0,6,1,2,1,2
            BGAB,DRA,RTA,#{@team_a.team_lead},20.0,6,1,2,1,2
            BGAB,DRB,"",#{@dir_b.team_lead},50.0,3,1,0,1,1
            BGAB,DRB,RTB,#{@team_b.team_lead},50.0,3,1,0,1,1
            BGCD,"","",#{@bizgrp_cd.team_lead},50.0,3,1,1,1,0
            BGCD,DRCD,"",#{@dir_cd.team_lead},50.0,3,1,1,1,0
            BGCD,DRCD,RTC,#{@team_c.team_lead},50.0,2,1,1,0,0
            BGCD,DRCD,RTD,#{@team_d.team_lead},0.0,1,0,0,1,0
            Total,"","","",33.3,12,3,3,3,3
          EOCSV
          report = R002AppealsPerformanceReport.new
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
          create :compliance_review, identifier: 'unassigned case'
        end
      end

      it 'does not raise an error' do
        report = R002AppealsPerformanceReport.new
        expect { report.run }.not_to raise_error
      end
    end

    # rubocop:disable Metrics/ParameterLists
    def create_appeal(received:, responded:, deadline:, team:, responder:, ident:)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create :compliance_review_with_response, responding_team: team, responder: responder, identifier: ident
        kase.external_deadline = Date.parse(deadline)
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.state_machine.respond!(responder)
            kase.update!(date_responded: Time.now, outcome_id: @outcome.id, info_held_status: @info_held)
            kase.state_machine.close!(kase.managing_team.users.first)
          end
        end
      end
      kase.save!
      kase
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
