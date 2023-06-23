require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R003BusinessUnitPerformanceReport do
    before(:all) do
      create_report_type(abbr: :r003)

      Team.all.map(&:destroy)
      Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
        @bizgrp_ab = create :business_group, name: "BGAB"
        @dir_a     = create :directorate, name: "DRA", business_group: @bizgrp_ab
        @dir_b     = create :directorate, name: "DRB", business_group: @bizgrp_ab
        @bizgrp_cd = create :business_group, name: "BGCD"
        @dir_cd    = create :directorate, name: "DRCD", business_group: @bizgrp_cd

        @bizgrp_e  = create :business_group, name: "BGDoom"
        @dir_e     = create :directorate, name: "DRDoom", business_group: @bizgrp_e

        @team_a = create :business_unit, name: "RTA", directorate: @dir_a
        @team_b = create :business_unit, name: "RTB", directorate: @dir_b
        @team_c = create :business_unit, name: "RTC", directorate: @dir_cd, moved_to_unit_id: 45
        @team_d = create :business_unit, name: "RTD", directorate: @dir_cd
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure

        @team_e = create :business_unit, name: "Doomed", directorate: @dir_e

        # deleted_at: Time.new(2017, 6, 29, 12, 0, 0)

        @responder_a = create :responder, responding_teams: [@team_a]
        @responder_b = create :responder, responding_teams: [@team_b]
        @responder_c = create :responder, responding_teams: [@team_c]
        @responder_d = create :responder, responding_teams: [@team_d]
        @responder_e = create :responder, responding_teams: [@team_e]

        @outcome = find_or_create :outcome, :granted
        @info_held = find_or_create :info_status, :held

        # create cases based on today's date of 30/6/2017
        create_case(received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - responded late")
        create_case(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - responded late")
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
        create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time", type: "irt")
        create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time", type: "irc")

        # flagged cases
        create_case(received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, flagged: true, ident: "case for team a - responded late")
        create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_a, responder: @responder_a, flagged: true, ident: "case for team a - open in time")
        create_case(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, flagged: true, ident: "case for team a - responded in time")
        create_case(received: "20170605", responded: nil,        deadline: "20170625", team: @team_b, responder: @responder_b, flagged: true, ident: "case for team b - open late")
        create_case(received: "20170605", responded: nil,        deadline: "20170702", team: @team_b, responder: @responder_b, flagged: true, ident: "case for team b - open in time")

        # case for soon-to-be-deactivated team
        create_case(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_e, responder: @responder_e, ident: "case for team e - Doom ed Team")
      end

      ###############
      # TODO Find a way not to create the extraneous teams in the first place
      ##############

      # delete extraneous teams
      Team.where("id > ?", @team_e.id).destroy_all
      Team.where("name = ?", "Operations").destroy_all
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    context "when defining the period" do
      context "and no period parameters passsed in" do
        it "defaults from beginning of year to now" do
          Timecop.freeze(Time.zone.local(2017, 12, 7, 12, 33, 44)) do
            report = described_class.new
            expect(report.reporting_period).to eq "1 Jan 2017 to 7 Dec 2017"
          end
        end
      end

      context "and period params are passed in" do
        it "uses the specify period" do
          d1 = Date.new(2017, 6, 1)
          d2 = Date.new(2017, 6, 30)
          report = described_class.new(period_start: d1, period_end: d2)
          expect(report.reporting_period).to eq "1 Jun 2017 to 30 Jun 2017"
        end
      end
    end

    describe "#title" do
      it "returns the report title" do
        expect(described_class.title).to eq "Business unit report (FOIs)"
      end
    end

    describe "#description" do
      it "returns the report description" do
        expect(described_class.description).to eq "Shows all FOI open cases and cases closed this month, in-time or late, by responding team"
      end
    end

    context "without business unit columns" do
      describe "#results" do
        before do
          Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
            report = described_class.new
            report.run
            @results = report.results
          end
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
              non_trigger_performance: 44.4,
              non_trigger_total: 9,
              non_trigger_responded_in_time: 2,
              non_trigger_responded_late: 2,
              non_trigger_open_in_time: 2,
              non_trigger_open_late: 3,
              trigger_performance: 60.0,
              trigger_total: 5,
              trigger_responded_in_time: 1,
              trigger_responded_late: 1,
              trigger_open_in_time: 2,
              trigger_open_late: 1,
              overall_performance: 50.0,
              overall_total: 14,
              overall_responded_in_time: 3,
              overall_responded_late: 3,
              overall_open_in_time: 4,
              overall_open_late: 4,
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
            })
        end
      end

      describe "#to_csv" do
        let(:report_csv) do
          Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
            d1 = Date.new(2017, 6, 4)
            d2 = Date.new(2017, 6, 30)
            report = described_class.new(period_start: d1, period_end: d2)
            report.run
            report.to_csv
          end
        end

        it "does rag ratings" do
          rag_ratings = report_csv.map do |row|
            row.map.with_index { |item, index| [index, item.rag_rating] if item.rag_rating }.compact
          end

          expected_rag_ratings = [
            [],
            (0..25).map { |x| [x, :blue] },
            (0..25).map { |x| [x, :grey] },
            [[8, :red], [14, :red], [20, :red]],
            [[8, :red], [14, :green], [20, :red]],
            [[8, :red], [14, :green], [20, :red]],
            [[8, :red], [14, :red], [20, :red]],
            [[8, :red], [14, :red], [20, :red]],
            [[8, :red], [20, :red]],
            [[8, :red], [20, :red]],
            [[8, :red], [20, :red]],
            [[8, :green], [20, :green]],
            [[8, :green], [20, :green]],
            [[8, :green], [20, :green]],
            [[8, :green], [20, :green]],
            [[8, :red], [14, :red], [20, :red]],
          ]

          expect(rag_ratings).to eq(expected_rag_ratings)
        end

        it "outputs results as a csv lines" do
          super_header = '"","","","","","","","",' \
            "Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases,Non-trigger cases," \
            "Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases,Trigger cases," \
            "Overall,Overall,Overall,Overall,Overall,Overall"
          header = "Business group,Directorate,Business unit,Business unit ID,New business unit ID,Responsible,Deactivated,Moved to," \
            "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
            "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
            "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late"
          expected_text = <<~EOCSV
            Business unit report (FOIs) - 4 Jun 2017 to 30 Jun 2017
            #{super_header}
            #{header}
            BGAB,"","",,,#{@bizgrp_ab.team_lead},"","",50.0,8,2,1,2,3,75.0,4,1,0,2,1,58.3,12,3,1,4,4
            BGAB,DRA,"",,,#{@dir_a.team_lead},"","",40.0,5,1,1,1,2,100.0,2,1,0,1,0,57.1,7,2,1,2,2
            BGAB,DRA,RTA,#{@team_a.id},,#{@team_a.team_lead},"","",40.0,5,1,1,1,2,100.0,2,1,0,1,0,57.1,7,2,1,2,2
            BGAB,DRB,"",,,#{@dir_b.team_lead},"","",66.7,3,1,0,1,1,50.0,2,0,0,1,1,60.0,5,1,0,2,2
            BGAB,DRB,RTB,#{@team_b.id},,#{@team_b.team_lead},"","",66.7,3,1,0,1,1,50.0,2,0,0,1,1,60.0,5,1,0,2,2
            BGCD,"","",,,#{@bizgrp_cd.team_lead},"","",66.7,3,1,1,1,0,,0,0,0,0,0,66.7,3,1,1,1,0
            BGCD,DRCD,"",,,#{@dir_cd.team_lead},"","",66.7,3,1,1,1,0,,0,0,0,0,0,66.7,3,1,1,1,0
            BGCD,DRCD,RTC,#{@team_c.id},#{@team_c.moved_to_unit_id},#{@team_c.team_lead},"","",50.0,2,1,1,0,0,,0,0,0,0,0,50.0,2,1,1,0,0
            BGCD,DRCD,RTD,#{@team_d.id},,#{@team_d.team_lead},"","",100.0,1,0,0,1,0,,0,0,0,0,0,100.0,1,0,0,1,0
            BGDoom,"","",,,#{@bizgrp_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0
            BGDoom,DRDoom,"",,,#{@dir_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0
            BGDoom,DRDoom,Doomed,#{@team_e.id},,#{@team_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0
            Total,"","",,,"","","",58.3,12,4,2,3,3,75.0,4,1,0,2,1,62.5,16,5,2,5,4
          EOCSV
          actual_lines = report_csv.map { |row| row.map(&:value) }
          expected_lines = expected_text.split("\n")
          actual_lines.zip(expected_lines).each do |actual, expected|
            expect(CSV.generate_line(actual).chomp).to eq(expected)
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
              trigger_performance: 75.0,
              trigger_total: 4,
              trigger_responded_in_time: 1,
              trigger_responded_late: 0,
              trigger_open_in_time: 2,
              trigger_open_late: 1,
              overall_performance: 58.3,
              overall_total: 12,
              overall_responded_in_time: 3,
              overall_responded_late: 1,
              overall_open_in_time: 4,
              overall_open_late: 4,
              bu_performance: 0.0,
              bu_total: 12,
              bu_responded_in_time: 0,
              bu_responded_late: 4,
              bu_open_in_time: 0,
              bu_open_late: 8,
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
              bu_performance: 0.0,
              bu_total: 3,
              bu_responded_in_time: 0,
              bu_responded_late: 2,
              bu_open_in_time: 0,
              bu_open_late: 1,
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
              bu_performance: 0.0,
              bu_total: 2,
              bu_responded_in_time: 0,
              bu_responded_late: 2,
              bu_open_in_time: 0,
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
              Business unit report (FOIs) - 5 Jun 2017 to 30 Jun 2017
              #{super_header}
              #{header}
              BGAB,"","",,,#{@bizgrp_ab.team_lead},"","",57.1,7,2,0,2,3,75.0,4,1,0,2,1,63.6,11,3,0,4,4,0.0,11,0,3,0,8
              BGAB,DRA,"",,,#{@dir_a.team_lead},"","",50.0,4,1,0,1,2,100.0,2,1,0,1,0,66.7,6,2,0,2,2,0.0,6,0,2,0,4
              BGAB,DRA,RTA,#{@team_a.id},,#{@team_a.team_lead},"","",50.0,4,1,0,1,2,100.0,2,1,0,1,0,66.7,6,2,0,2,2,0.0,6,0,2,0,4
              BGAB,DRB,"",,,#{@dir_b.team_lead},"","",66.7,3,1,0,1,1,50.0,2,0,0,1,1,60.0,5,1,0,2,2,0.0,5,0,1,0,4
              BGAB,DRB,RTB,#{@team_b.id},,#{@team_b.team_lead},"","",66.7,3,1,0,1,1,50.0,2,0,0,1,1,60.0,5,1,0,2,2,0.0,5,0,1,0,4
              BGCD,"","",,,#{@bizgrp_cd.team_lead},"","",100.0,2,1,0,1,0,,0,0,0,0,0,100.0,2,1,0,1,0,0.0,2,0,1,0,1
              BGCD,DRCD,"",,,#{@dir_cd.team_lead},"","",100.0,2,1,0,1,0,,0,0,0,0,0,100.0,2,1,0,1,0,0.0,2,0,1,0,1
              BGCD,DRCD,RTC,#{@team_c.id},#{@team_c.moved_to_unit_id},#{@team_c.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0,0.0,1,0,1,0,0
              BGCD,DRCD,RTD,#{@team_d.id},,#{@team_d.team_lead},"","",100.0,1,0,0,1,0,,0,0,0,0,0,100.0,1,0,0,1,0,0.0,1,0,0,0,1
              BGDoom,"","",,,#{@bizgrp_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0,0.0,1,0,1,0,0
              BGDoom,DRDoom,"",,,#{@dir_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0,0.0,1,0,1,0,0
              BGDoom,DRDoom,Doomed,#{@team_e.id},,#{@team_e.team_lead},"","",100.0,1,1,0,0,0,,0,0,0,0,0,100.0,1,1,0,0,0,0.0,1,0,1,0,0
              Total,"","",,,"","","",70.0,10,4,0,3,3,75.0,4,1,0,2,1,71.4,14,5,0,5,4,0.0,14,0,5,0,9
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

    def create_case(received:, responded:, deadline:, team:, responder:, ident:, flagged: false, type: "std")
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        factory = {
          std: :case_with_response,
          irt: :accepted_timeliness_review,
          irc: :accepted_compliance_review,
        }[type.to_sym]

        kase = create(factory, responding_team: team, responder:, identifier: ident, received_date:)
        kase.external_deadline = Date.parse(deadline)
        if flagged == true
          CaseFlagForClearanceService.new(user: kase.managing_team.users.first, kase:, team: @team_dacu_disclosure).call
        end
        unless responded_date.nil?
          Timecop.freeze responded_date + 14.hours do
            kase.state_machine.respond!(acting_user: responder, acting_team: team)
            kase.update!(date_responded: Time.zone.now, outcome_id: @outcome.id, info_held_status: @info_held)
            kase.state_machine.close!(acting_user: kase.managing_team.users.first, acting_team: kase.managing_team)
          end
        end
      end
      kase.save!
      kase
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
