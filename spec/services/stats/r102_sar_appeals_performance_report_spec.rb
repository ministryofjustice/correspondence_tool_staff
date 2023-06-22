require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R102SarAppealsPerformanceReport do
    before(:all) do
      create_report_type(abbr: :r102)

      Team.all.map(&:destroy)
      Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
        @bizgrp_ab = create :business_group, name: "BGAB"
        @dir_a     = create :directorate, name: "DRA", business_group: @bizgrp_ab
        @dir_b     = create :directorate, name: "DRB", business_group: @bizgrp_ab
        @bizgrp_cd = create :business_group, name: "BGCD"
        @dir_cd    = create :directorate, name: "DRCD", business_group: @bizgrp_cd

        @team_dacu_disclosure = find_or_create :team_dacu_disclosure
        @team_dacu_bmt = find_or_create :team_disclosure_bmt
        @team_a = create :business_unit, name: "RTA", directorate: @dir_a
        @team_b = create :business_unit, name: "RTB", directorate: @dir_b
        @team_c = create :business_unit, name: "RTC", directorate: @dir_cd, moved_to_unit_id: 8
        @team_d = create :business_unit, name: "RTD", directorate: @dir_cd

        @responder_a = create :responder, responding_teams: [@team_a]
        @responder_b = create :responder, responding_teams: [@team_b]
        @responder_c = create :responder, responding_teams: [@team_c]
        @responder_d = create :responder, responding_teams: [@team_d]

        @outcome = find_or_create :outcome, :granted
        @info_held = find_or_create :info_status, :held

        # standard SARs and IRs which should be ignored by report
        create_sar(received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time", case_type: :accepted_sar)
        create_sar(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "case for team c - responded in time", case_type: :accepted_sar)
        create_sar(received: "20170607", responded: "20170620", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - responded in time", case_type: :accepted_sar)
        create_sar(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "case for team a - responded in time", case_type: :accepted_sar)
        create_interal_review(received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - responded late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - responded late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - open late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "case for team a - open late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170702", team: @team_a, responder: @responder_a, ident: "case for team a - open in time", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "case for team a - responded in time", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - open late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170702", team: @team_b, responder: @responder_b, ident: "case for team b - open in time", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170607", responded: "20170620", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - responded in time", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170604", responded: "20170629", deadline: "20170625", team: @team_c, responder: @responder_c, ident: "case for team c - responded late", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170606", responded: "20170625", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "case for team c - responded in time", case_type: :compliance_review_with_response)
        create_interal_review(received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time", case_type: :compliance_review_with_response)

        # ICO FOIs that should be ignored based on today's date of 30/6/2017
        create_ico(type: :foi, received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico foi for team a - responded late")
        create_ico(type: :foi, received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico foi for team a - responded late")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico foi for team a - open late")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico foi for team a - open late")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170702", team: @team_a, responder: @responder_a, ident: "ico foi for team a - open in time")
        create_ico(type: :foi, received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "ico foi for team a - responded in time")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170625", team: @team_b, responder: @responder_b, ident: "ico foi for team b - open late")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170702", team: @team_b, responder: @responder_b, ident: "ico foi for team b - open in time")
        create_ico(type: :foi, received: "20170607", responded: "20170620", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "ico foi for team b - responded in time")
        create_ico(type: :foi, received: "20170604", responded: "20170629", deadline: "20170625", team: @team_c, responder: @responder_c, ident: "ico foi for team c - responded late")
        create_ico(type: :foi, received: "20170606", responded: "20170625", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "ico foi for team c - responded in time")
        create_ico(type: :foi, received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "ico foi for team d - open in time")

        # ICO SARs based on today's date of 30/6/2017
        create_ico(type: :sar, received: "20170601", responded: "20170628", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico sar for team a - responded late")
        create_ico(type: :sar, received: "20170604", responded: "20170629", deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico sar for team a - responded late")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico sar for team a - open late")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170625", team: @team_a, responder: @responder_a, ident: "ico sar for team a - open late")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170702", team: @team_a, responder: @responder_a, ident: "ico sar for team a - open in time")
        create_ico(type: :sar, received: "20170606", responded: "20170625", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "ico sar for team a - responded in time")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170625", team: @team_b, responder: @responder_b, ident: "ico sar for team b - open late")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170702", team: @team_b, responder: @responder_b, ident: "ico sar for team b - open in time")
        create_ico(type: :sar, received: "20170607", responded: "20170620", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "ico sar for team b - responded in time")

        create_ico(type: :sar, received: "20170604", responded: "20170629", deadline: "20170625", team: @team_c, responder: @responder_c, ident: "ico sar for team c - responded late")
        create_ico(type: :sar, received: "20170606", responded: "20170625", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "ico sar for team c - responded in time")
        create_ico(type: :sar, received: "20170605", responded: nil,        deadline: "20170702", team: @team_d, responder: @responder_d, ident: "ico sar for team d - open in time")

        # SAR Internal Reviews
        create_sar_ir(received: "20170605", deadline: "20170702", team: @team_d, responder: @responder_d, ident: "case for team d - open in time", case_type: :closed_sar_internal_review)
        create_sar_ir(received: "20170606", deadline: "20170630", team: @team_c, responder: @responder_c, ident: "case for team c - responded in time", case_type: :closed_sar_internal_review)
        create_sar_ir(received: "20170607", deadline: "20170625", team: @team_b, responder: @responder_b, ident: "case for team b - responded in time", case_type: :closed_sar_internal_review)
        create_sar_ir(received: "20170606", deadline: "20170630", team: @team_a, responder: @responder_a, ident: "case for team a - responded in time", case_type: :closed_sar_internal_review)
      end

      required_teams = [@bizgrp_ab, @dir_a, @dir_b, @bizgrp_cd, @dir_cd, @team_dacu_disclosure, @team_dacu_bmt, @team_a, @team_b, @team_c, @team_d]
      Team.where.not(id: required_teams.map(&:id)).destroy_all
    end

    after(:all) do
      DbHousekeeping.clean(seed: false)
    end

    describe "#title" do
      it "returns the report title" do
        expect(described_class.title).to eq "SAR Appeal performance stats"
      end
    end

    describe "#description" do
      it "returns the report description" do
        expect(described_class.description).to eq "Shows all ICO appeals, and SAR IRs which are open, or have been closed this month, analysed by timeliness"
      end
    end

    describe "#results" do
      before do
        Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
          report = described_class.new
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
            deactivated: "",
            moved: "",
            responsible: @bizgrp_ab.team_lead,
            ico_appeal_performance: 44.4,
            ico_appeal_total: 9,
            ico_appeal_responded_in_time: 2,
            ico_appeal_responded_late: 2,
            ico_appeal_open_in_time: 2,
            ico_appeal_open_late: 3,
            sar_ir_appeal_performance: 100.0,
            sar_ir_appeal_total: 2,
            sar_ir_appeal_responded_in_time: 2,
            sar_ir_appeal_responded_late: 0,
            sar_ir_appeal_open_in_time: 0,
            sar_ir_appeal_open_late: 0,
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
            deactivated: "",
            moved: "",
            responsible: @bizgrp_cd.team_lead,
            ico_appeal_performance: 66.7,
            ico_appeal_total: 3,
            ico_appeal_responded_in_time: 1,
            ico_appeal_responded_late: 1,
            ico_appeal_open_in_time: 1,
            ico_appeal_open_late: 0,
            sar_ir_appeal_performance: 100.0,
            sar_ir_appeal_total: 2,
            sar_ir_appeal_responded_in_time: 2,
            sar_ir_appeal_responded_late: 0,
            sar_ir_appeal_open_in_time: 0,
            sar_ir_appeal_open_late: 0,
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
            deactivated: "",
            moved: "",
            responsible: @team_c.team_lead,
            ico_appeal_performance: 50.0,
            ico_appeal_total: 2,
            ico_appeal_responded_in_time: 1,
            ico_appeal_responded_late: 1,
            ico_appeal_open_in_time: 0,
            ico_appeal_open_late: 0,
            sar_ir_appeal_performance: 100.0,
            sar_ir_appeal_total: 1,
            sar_ir_appeal_responded_in_time: 1,
            sar_ir_appeal_responded_late: 0,
            sar_ir_appeal_open_in_time: 0,
            sar_ir_appeal_open_late: 0,
          })
      end
    end

    describe "#to_csv" do
      it "outputs results as a csv lines" do
        Timecop.freeze Time.zone.local(2017, 6, 30, 12, 0, 0) do
          super_header = '"","","","",' \
            "SAR Internal reviews,SAR Internal reviews,SAR Internal reviews,SAR Internal reviews,SAR Internal reviews,SAR Internal reviews," \
            "ICO appeals,ICO appeals,ICO appeals,ICO appeals,ICO appeals,ICO appeals"
          header = "Business group,Directorate,Business unit,Responsible," \
            "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late," \
            "Performance %,Total received,Responded - in time,Responded - late,Open - in time,Open - late"
          expected_text = <<~EOCSV
            SAR Appeal performance stats - 1 Jan 2017 to 30 Jun 2017
            #{super_header}
            #{header}
            BGAB,"","",#{@bizgrp_ab.team_lead},100.0,2,2,0,0,0,44.4,9,2,2,2,3
            BGAB,DRA,"",#{@dir_a.team_lead},100.0,1,1,0,0,0,33.3,6,1,2,1,2
            BGAB,DRA,RTA,#{@team_a.team_lead},100.0,1,1,0,0,0,33.3,6,1,2,1,2
            BGAB,DRB,"",#{@dir_b.team_lead},100.0,1,1,0,0,0,66.7,3,1,0,1,1
            BGAB,DRB,RTB,#{@team_b.team_lead},100.0,1,1,0,0,0,66.7,3,1,0,1,1
            BGCD,"","",#{@bizgrp_cd.team_lead},100.0,2,2,0,0,0,66.7,3,1,1,1,0
            BGCD,DRCD,"",#{@dir_cd.team_lead},100.0,2,2,0,0,0,66.7,3,1,1,1,0
            BGCD,DRCD,RTC,#{@team_c.team_lead},100.0,1,1,0,0,0,50.0,2,1,1,0,0
            BGCD,DRCD,RTD,#{@team_d.team_lead},100.0,1,1,0,0,0,100.0,1,0,0,1,0
            Total,"","","",100.0,4,4,0,0,0,50.0,12,3,3,3,3
          EOCSV
          report = described_class.new
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
          create :compliance_review, identifier: "unassigned case"
        end
      end

      it "does not raise an error" do
        report = described_class.new
        expect { report.run }.not_to raise_error
      end
    end

    def create_sar(received:, responded:, deadline:, team:, responder:, ident:, case_type:)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create case_type, responding_team: team, responder:, identifier: ident
        kase.external_deadline = Date.parse(deadline)
        unless responded_date.nil?
          Timecop.freeze responded_date  do
            kase.update!(date_responded: Time.zone.now, outcome_id: @outcome.id, info_held_status: @info_held)
            kase.state_machine.respond_and_close!(acting_user: responder, acting_team: team)
          end
        end
      end
      kase.save!
      kase
    end

    def create_sar_ir(received:, deadline:, team:, responder:, ident:, case_type:)
      received_date = Date.parse(received)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create case_type, responding_team: team, responder:, identifier: ident
        kase.external_deadline = Date.parse(deadline)
      end
      kase.save!
      kase
    end

    def create_interal_review(received:, responded:, deadline:, team:, responder:, ident:, case_type:)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      kase = nil
      Timecop.freeze(received_date + 10.hours) do
        kase = create case_type, responding_team: team, responder:, identifier: ident
        kase.external_deadline = Date.parse(deadline)
        unless responded_date.nil?
          Timecop.freeze responded_date do
            kase.state_machine.respond!(acting_user: responder, acting_team: team)
            kase.update!(date_responded: Time.zone.now, outcome_id: @outcome.id, info_held_status: @info_held)
            kase.state_machine.close!(acting_user: kase.managing_team.users.first, acting_team: kase.managing_team)
          end
        end
      end
      kase.save!
      kase
    end

    def create_ico(type:, received:, responded:, deadline:, team:, responder:, ident:)
      received_date = Date.parse(received)
      responded_date = responded.nil? ? nil : Date.parse(responded)
      deadline_date = Date.parse(deadline)
      kase = nil
      if responded_date.nil?
        factory = "accepted_ico_#{type}_case".to_sym
        kase = create factory,
                      creation_time: received_date,
                      external_deadline: deadline_date,
                      responding_team: team,
                      responder:,
                      identifier: ident
      else
        factory = "responded_ico_#{type}_case".to_sym
        kase = create factory,
                      creation_time: received_date,
                      external_deadline: deadline_date,
                      responding_team: team,
                      responder:,
                      date_responded: responded_date,
                      identifier: ident
      end
      kase
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
