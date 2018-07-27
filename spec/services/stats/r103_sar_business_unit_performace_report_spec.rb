require 'rails_helper'

module Stats
  describe R103SarBusinessUnitPerformanceReport do

    before(:all) do
      create :report_type, :r103
    end

    after(:all) do
      ReportType.r103.destroy
    end

    context 'date management, titles, description, etc' do
      context 'defining the period' do
        context 'no period parameters passsed in' do
          it 'defaults from beginning of year to now' do
            Timecop.freeze(Time.local(2017, 12, 7, 12,33,44)) do
              report = R103SarBusinessUnitPerformanceReport.new
              expect(report.__send__(:reporting_period)).to eq '1 Jan 2017 to 7 Dec 2017'
            end
          end
        end

        context 'period params are passed in' do
          it 'uses the specify period' do
            d1 = Date.new(2017, 6, 1)
            d2 = Date.new(2017, 6, 30)
            report = R103SarBusinessUnitPerformanceReport.new(d1, d2)
            expect(report.__send__(:reporting_period)).to eq '1 Jun 2017 to 30 Jun 2017'
          end
        end
      end

      describe '#title' do
        it 'returns the report title' do
          expect(R103SarBusinessUnitPerformanceReport.title).to eq 'Business unit report (SARs)'
        end
      end

      describe '#description' do
        it 'returns the report description' do
          expect(R103SarBusinessUnitPerformanceReport.description).to eq 'Shows all SAR open cases and cases closed this month, in-time or late, by responding team (excluding TMMs)'
        end
      end
    end

    context 'data' do
      before(:all) do
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

        @tmm = create :refusal_reason, :tmm
        @vex = create :refusal_reason, :vex

        # create cases based on today's date of 30/6/2017
        create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_a, responder: @responder_a, type: :vex, ident: 'case for team a - responded late')
        create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_a, responder: @responder_a, type: :vex, ident: 'case for team a - responded late')
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

        # create some SAR TMM cases which should be ignored
        create_case(received: '20170601', responded: '20170628', deadline: '20170625', team: @team_a, responder: @responder_a, type: :tmm, ident: 'case for team a - responded late')
        create_case(received: '20170604', responded: '20170629', deadline: '20170625', team: @team_a, responder: @responder_a, type: :tmm, ident: 'case for team a - responded late')
        create_case(received: '20170606', responded: '20170625', deadline: '20170630', team: @team_a, responder: @responder_a, type: :tmm, ident: 'case for team a - responded in time')

        # create some FOI cases which should be ignored
        create :closed_case
        create :closed_case

        # delete extraneous teams
        Team.where('id > ?', @team_d.id).destroy_all
      end

      after(:all)  { DbHousekeeping.clean }

      context 'without business unit columns' do

        # We only test that the correct cases are being selected for analysis.  The
        # analysis work, rolling up of business group and directorate toatls and calcualtion
        # of percentages is carried out in BasePerformanceUnitReport, and is fully testing
        # by the R003PerfomanceReport spec.
        #
        describe '#scope' do
          before do
            Timecop.freeze Time.new(2017, 6, 30, 12, 0, 0) do

              report = R103SarBusinessUnitPerformanceReport.new
              @scope = report.case_scope
            end
          end

          it 'selects only SAR cases' do
            expect(@scope.size).to eq 12
            expect(@scope.map(&:type).uniq).to eq ['Case::SAR']
          end

          it 'excludes TMM cases' do
            expect(@scope.map(&:refusal_reason_id)).not_to include(@tmm.id)
          end

        end
      end


      #rubocop:disable Metrics/ParameterLists
      def create_case(received:, responded:, deadline:, team:, responder:, ident:, flagged: false, type: nil)
        received_date = Date.parse(received)
        responded_date = responded.nil? ? nil : Date.parse(responded)
        kase = nil
        Timecop.freeze(received_date + 10.hours) do
          factory = :accepted_sar
          kase = create factory, responding_team: team, responder: responder, identifier: ident
          kase.external_deadline = Date.parse(deadline)
          if flagged == true
            CaseFlagForClearanceService.new(user: kase.managing_team.users.first, kase: kase, team: @team_dacu_disclosure).call
          end
          unless responded_date.nil?
            Timecop.freeze responded_date + 14.hours do
              kase.date_responded = Time.now
              kase.state_machine.close!(acting_user: responder, acting_team: team)
            end
          end
        end


        if type.present?
          refusal_reason = CaseClosure::RefusalReason.__send__(type)
          kase.refusal_reason = refusal_reason
        end
        kase.save!
        kase
      end
      #rubocop:enable Metrics/ParameterLists


    end
  end
end
