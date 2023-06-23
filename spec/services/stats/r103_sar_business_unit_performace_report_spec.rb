require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R103SarBusinessUnitPerformanceReport do
    before(:all) do
      create_report_type(abbr: :r103)

      @bizgrp_ab = create :business_group, name: "BGAB"
      @dir_a     = create :directorate, name: "DRA", business_group: @bizgrp_ab
      @dir_b     = create :directorate, name: "DRB", business_group: @bizgrp_ab
      @bizgrp_cd = create :business_group, name: "BGCD"
      @dir_cd    = create :directorate, name: "DRCD", business_group: @bizgrp_cd

      @team_a = create :business_unit, name: "RTA", directorate: @dir_a
      @team_b = create :business_unit, name: "RTB", directorate: @dir_b
      @team_c = create :business_unit, name: "RTC", directorate: @dir_cd, moved_to_unit_id: 10
      @team_d = create :business_unit, name: "RTD", directorate: @dir_cd
      @team_dacu_disclosure = find_or_create :team_dacu_disclosure

      @responder_a = create :responder, responding_teams: [@team_a]
      @responder_b = create :responder, responding_teams: [@team_b]
      @responder_c = create :responder, responding_teams: [@team_c]
      @responder_d = create :responder, responding_teams: [@team_d]

      @sar_tmm = create :refusal_reason, :sar_tmm
      @vex = create :refusal_reason, :vex

      # create cases based on today's date of 30/6/2017
      case_1 = create_case(received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, type: :vex, ident: "case for team a - responded late")
      case_2 = create_case(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, type: :vex, ident: "case for team a - responded late")
      create_case(received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - open late")
      create_case(received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - open late")
      create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_a, responder: @responder_a, ident: "case for team a - open in time")
      create_case(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "case for team a - responded in time")
      create_case(received: "20170605", responded: nil,        deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - open late")
      create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_b, responder: @responder_b, ident: "case for team b - open in time")
      create_case(received: "20170607", responded: "20170620", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - responded in time")
      create_case(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_c, responder: @responder_c, ident: "case for team c - responded late")
      create_case(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "case for team c - responded in time")
      create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time")

      # create some SAR TMM cases which should be ignored
      create_case(received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, type: :sar_tmm, ident: "case for team a - responded late")
      create_case(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, type: :sar_tmm, ident: "case for team a - responded late")
      create_case(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, type: :sar_tmm, ident: "case for team a - responded in time")

      # create some SAR IR cases which should be ignored
      create(:sar_internal_review, original_case: case_1)
      create(:closed_sar_internal_review, original_case: case_2)

      # create some FOI cases which should be ignored
      create :closed_case
      create :closed_case

      # delete extraneous teams
      Team.where("id > ?", @team_d.id).destroy_all
      Team.where("name = ?", "Operations").destroy_all
      Team.where("name like ?", "%Responder%").destroy_all
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "date management, titles, description, etc" do
      context "when defining the period" do
        context "and no period parameters passsed in" do
          it "defaults from beginning of year to now" do
            Timecop.freeze(Time.zone.local(2017, 12, 7, 12, 33, 44)) do
              report = described_class.new
              expect(report.__send__(:reporting_period)).to eq "1 Jan 2017 to 7 Dec 2017"
            end
          end
        end

        context "and period params are passed in" do
          it "uses the specify period" do
            d1 = Date.new(2017, 6, 1)
            d2 = Date.new(2017, 6, 30)
            report = described_class.new(period_start: d1, period_end: d2)
            expect(report.__send__(:reporting_period)).to eq "1 Jun 2017 to 30 Jun 2017"
          end
        end
      end

      describe "#title" do
        it "returns the report title" do
          expect(described_class.title).to eq "Business unit report (SARs)"
        end
      end

      describe "#description" do
        it "returns the report description" do
          expect(described_class.description).to eq "Shows all SAR open cases and cases closed this month, in-time or late, by responding team (excluding TMMs)"
        end
      end
    end

    describe "data" do
      context "without business unit columns" do
        # We only test that the correct cases are being selected for analysis.  The
        # analysis work, rolling up of business group and directorate toatls and calcualtion
        # of percentages is carried out in BasePerformanceUnitReport, and is fully testing
        # by the R003PerfomanceReport spec.
        #
        describe "#scope" do
          before do
            Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
              d1 = Date.new(2017, 6, 4)
              d2 = Date.new(2017, 6, 30)
              report = described_class.new(period_start: d1, period_end: d2)
              @scope = report.case_scope
            end
          end

          it "selects only SAR cases" do
            expect(@scope.size).to eq 12
            expect(@scope.map(&:type).uniq).to eq ["Case::SAR::Standard"]
          end

          it "excludes TMM cases" do
            expect(@scope.map(&:refusal_reason_id)).not_to include(@sar_tmm.id)
          end
        end
      end

      context "with business unit columns" do
        describe "#results" do
          before do
            Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
              report = described_class.new(period_start: Date.new(2017, 6, 2), period_end: Time.zone.today, generate_bu_columns: true)
              report.run
              @results = report.results
            end
          end

          it "generates hierarchy starting with business_groups" do
            expect(@results.keys).to eq Team.hierarchy.map(&:id) + [:total]
          end

          it "adds up directorate stats in each business_group" do
            expect(@results[@bizgrp_ab.id])
              .to eq({
                business_group: @bizgrp_ab.name,
                directorate: "",
                business_unit: "",
                business_unit_id: nil,
                new_business_unit_id: nil,
                responsible: @bizgrp_ab.team_lead,
                deactivated: "",
                moved: "",
                non_trigger_performance: 50.0,
                non_trigger_total: 8,
                non_trigger_responded_in_time: 2,
                non_trigger_responded_late: 1,
                non_trigger_open_in_time: 2,
                non_trigger_open_late: 3,
                trigger_performance: nil,
                trigger_total: 0,
                trigger_responded_in_time: 0,
                trigger_responded_late: 0,
                trigger_open_in_time: 0,
                trigger_open_late: 0,
                overall_performance: 50.0,
                overall_total: 8,
                overall_responded_in_time: 2,
                overall_responded_late: 1,
                overall_open_in_time: 2,
                overall_open_late: 3,
                bu_performance: 100.0,
                bu_total: 8,
                bu_responded_in_time: 0,
                bu_responded_late: 0,
                bu_open_in_time: 8,
                bu_open_late: 0,
              })
          end

          it "adds up business_unit stats in each directorate" do
            expect(@results[@bizgrp_cd.id])
              .to eq({
                business_group: @bizgrp_cd.name,
                directorate: "",
                business_unit: "",
                business_unit_id: nil,
                new_business_unit_id: nil,
                responsible: @bizgrp_cd.team_lead,
                deactivated: "",
                moved: "",
                non_trigger_performance: 66.7,
                non_trigger_total: 3,
                non_trigger_responded_in_time: 1,
                non_trigger_responded_late: 1,
                non_trigger_open_in_time: 1,
                non_trigger_open_late: 0,
                trigger_performance: nil,
                trigger_total: 0,
                trigger_responded_in_time: 0,
                trigger_responded_late: 0,
                trigger_open_in_time: 0,
                trigger_open_late: 0,
                overall_performance: 66.7,
                overall_total: 3,
                overall_responded_in_time: 1,
                overall_responded_late: 1,
                overall_open_in_time: 1,
                overall_open_late: 0,
                bu_performance: 100.0,
                bu_total: 3,
                bu_responded_in_time: 0,
                bu_responded_late: 0,
                bu_open_in_time: 3,
                bu_open_late: 0,
              })
          end

          it "adds up individual business_unit stats" do
            expect(@results[@team_c.id])
              .to eq({
                business_group: @bizgrp_cd.name,
                directorate: @dir_cd.name,
                business_unit: @team_c.name,
                business_unit_id: @team_c.id,
                new_business_unit_id: @team_c.moved_to_unit_id,
                responsible: @team_c.team_lead,
                deactivated: "",
                moved: "",
                non_trigger_performance: 50.0,
                non_trigger_total: 2,
                non_trigger_responded_in_time: 1,
                non_trigger_responded_late: 1,
                non_trigger_open_in_time: 0,
                non_trigger_open_late: 0,
                trigger_performance: nil,
                trigger_total: 0,
                trigger_responded_in_time: 0,
                trigger_responded_late: 0,
                trigger_open_in_time: 0,
                trigger_open_late: 0,
                overall_performance: 50.0,
                overall_total: 2,
                overall_responded_in_time: 1,
                overall_responded_late: 1,
                overall_open_in_time: 0,
                overall_open_late: 0,
                bu_performance: 100.0,
                bu_total: 2,
                bu_responded_in_time: 0,
                bu_responded_late: 0,
                bu_open_in_time: 2,
                bu_open_late: 0,
              })
          end
        end

        describe "#to_csv" do
          it "outputs results as a csv lines" do
            Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
              super_header = '"","","","","","","","",' \
                "Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases," \
                "Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases," \
                "Overall,Overall,Overall,Overall,Overall,Overall," \
                "Business unit,Business unit,Business unit,Business unit,Business unit,Business unit"
              header = "Business group,Directorate,Business unit,Business unit ID,New business unit ID,Responsible,Deactivated,Moved to," \
                "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
                "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
                "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
                "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late"
              expected_text = <<~EOCSV
                Business unit report (SARs) - 5 Jun 2017 to 30 Jun 2017
                #{super_header}
                #{header}
                BGAB,"","",,,#{@bizgrp_ab.team_lead},"","",57.1,7,2,0,2,3,,0,0,0,0,0,57.1,7,2,0,2,3,100.0,7,0,0,7,0
                BGAB,DRA,"",,,#{@dir_a.team_lead},"","",50.0,4,1,0,1,2,,0,0,0,0,0,50.0,4,1,0,1,2,100.0,4,0,0,4,0
                BGAB,DRA,RTA,#{@team_a.id},,#{@team_a.team_lead},"","",50.0,4,1,0,1,2,,0,0,0,0,0,50.0,4,1,0,1,2,100.0,4,0,0,4,0
                BGAB,DRB,"",,,#{@dir_b.team_lead},"","",66.7,3,1,0,1,1,,0,0,0,0,0,66.7,3,1,0,1,1,100.0,3,0,0,3,0
                BGAB,DRB,RTB,#{@team_b.id},,#{@team_b.team_lead},"","",66.7,3,1,0,1,1,,0,0,0,0,0,66.7,3,1,0,1,1,100.0,3,0,0,3,0
                BGCD,"","",,,#{@bizgrp_cd.team_lead},"","",100.0,2,1,0,1,0,,0,0,0,0,0,100.0,2,1,0,1,0,100.0,2,0,0,2,0
                BGCD,DRCD,"",,,#{@dir_cd.team_lead},"","",100.0,2,1,0,1,0,,0,0,0,0,0,100.0,2,1,0,1,0,100.0,2,0,0,2,0
                BGCD,DRCD,RTC,#{@team_c.id},#{@team_c.moved_to_unit_id},#{@team_c.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0,100.0,1,0,0,1,0
                BGCD,DRCD,RTD,#{@team_d.id},,#{@team_d.team_lead},"","",100.0,1,0,0,1,0,,0,0,0,0,0,100.0,1,0,0,1,0,100.0,1,0,0,1,0
                Total,"","",,,"","","",66.7,9,3,0,3,3,,0,0,0,0,0,66.7,9,3,0,3,3,100.0,9,0,0,9,0
              EOCSV
              report = described_class.new(period_start: Date.new(2017, 6, 5), period_end: Time.zone.today, generate_bu_columns: true)
              report.run
              actual_lines = report.to_csv.map { |row| row.map(&:value) }
              expected_lines = expected_text.split("\n")
              actual_lines.zip(expected_lines).each do |actual, expected|
                expect(CSV.generate_line(actual).chomp).to eq(expected)
              end
            end
          end
        end

        context "with a case in the db that is unassigned" do
          before do
            Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
              create :case, identifier: "unassigned case"
            end
          end

          it "does not raise an error" do
            report = described_class.new
            expect { report.run }.not_to raise_error
          end
        end
      end
    end

    def create_case(received:, responded:, deadline:, team:, responder:, ident:, flagged: false, type: nil)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        factory = :accepted_sar
        kase = create(factory, responding_team: team, responder:, identifier: ident, received_date:)
        kase.external_deadline = Date.parse(deadline)
        if flagged
          CaseFlagForClearanceService.new(user: kase.managing_team.users.first, kase:, team: @team_dacu_disclosure).call
        end
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.date_responded = Time.zone.now
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
  end
end
# rubocop:enable RSpec/BeforeAfterAll
