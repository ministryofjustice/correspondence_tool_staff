require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R005MonthlyPerformanceReport do
    before(:all) { create_report_type(abbr: :r005) }

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe ".title" do
      it "returns the title" do
        expect(described_class.title).to eq "Monthly report"
      end
    end

    describe ".case_analyzer" do
      it "returns correct case_analyzer" do
        expect(described_class.case_analyzer).to eq Stats::CaseAnalyser
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Includes performance data about FOI requests we received and responded to from the beginning of the year by month."
      end
    end

    describe "#run and #to_csv" do
      let(:report_csv) do
        Timecop.freeze(2017, 5, 2, 13, 14, 15) do
          2.times { create_case(:trigger_responded_in_time, 3) }
          create_case(:trigger_responded_late, 3)
          3.times { create_case(:trigger_responded_in_time, 4) }
          2.times { create_case(:non_trigger_open_in_time, 4) }
          create_case(:non_trigger_open_late, 4)
          2.times { create_case(:non_trigger_open_late, 3, case_type: :case) } # unassigned

          # these should be ignored
          create :compliance_review
          create :timeliness_review
          create :sar_case

          report = described_class.new
          report.run
          report.to_csv
        end
      end
      let!(:results) { report_csv.map { |row| row.map(&:value) } }

      describe "#case_scope" do
        it "only selects FOI non compliance cases" do
          Timecop.freeze(Time.zone.local(2017, 12, 7, 12, 33, 44)) do
            report = described_class.new
            expect(report.case_scope.map(&:type).uniq).to eq ["Case::FOI::Standard"]
          end
        end
      end

      it "does rag ratings" do
        rag_ratings = report_csv.map do |row|
          row.map.with_index { |item, index| [index, item.rag_rating] if item.rag_rating }.compact
        end

        expected = [
          [],
          [],
          [],
          (0..18).map { |c| [c, :blue] },       # Headings
          (0..18).map { |c| [c, :grey] },       # Column Names
          [],
          [],
          [[1, :red], [7, :red], [13, :red]],   # March
          [[1, :red], [7, :green], [13, :amber]], # April
          [],
          [[1, :red], [7, :amber], [13, :red]],   # Totals
        ]

        expect(rag_ratings).to eq(expected)
      end

      it "contains report name and reporting period in row 1 column 1" do
        row_1 = results.first
        expect(row_1).to eq ["Monthly report - 1 Jan 2017 to 2 May 2017"]
      end

      it "contains expected superheadings in row 2" do
        row_2 = results[1]
        row_3 = results[2]
        row_4 = results[3]
        expect(row_2).to eq described_class.report_notes
        expect(row_3).to include(/.*2017-05-02/)
        expect(row_4).to eq [""] + ["Non-trigger cases"] * 6 + ["Trigger cases"] * 6 + %w[Overall] * 6
      end

      it "contains expected headings in row 3" do
        row_5 = results[4]
        expect(row_5[0]).to eq "Month"
        [1, 7, 13].each { |i| expect(row_5[i]).to eq "Performance %" }
        [2, 8, 14].each { |i| expect(row_5[i]).to eq "Total received" }
        [3, 9, 15].each { |i| expect(row_5[i]).to eq "Responded - in time" }
        [4, 10, 16].each { |i| expect(row_5[i]).to eq "Responded - late" }
        [5, 11, 17].each { |i| expect(row_5[i]).to eq "Open - in time" }
        [6, 12, 18].each { |i| expect(row_5[i]).to eq "Open - late" }
      end

      it "contains month names year to date in first column" do
        expect(results[5..10].map { |m| m[0] }).to eq %w[January February March April May Total]
      end

      context "when monthly figures" do
        let(:expected_results) do
          {
            "March" => {
              month_name: "March",
              non_trigger_performance_pctg: 0.0,
              non_trigger_total: 2,
              non_trigger_responded_in_time: 0,
              non_trigger_responded_late: 0,
              non_trigger_open_in_time: 0,
              non_trigger_open_late: 2,
              trigger_perfomance_pctg: 66.7,
              trigger_total: 3,
              trigger_responded_in_time: 2,
              trigger_responded_late: 1,
              trigger_open_in_time: 0,
              trigger_open_late: 0,
              overall_performance_pctg: 40.0,
              overall_total: 5,
              overall_responded_in_time: 2,
              overall_responded_late: 1,
              overall_open_in_time: 0,
              overall_open_late: 2,
            },
            "April" => {
              month_name: "April",
              non_trigger_performance_pctg: 66.7,
              non_trigger_total: 3,
              non_trigger_responded_in_time: 0,
              non_trigger_responded_late: 0,
              non_trigger_open_in_time: 2,
              non_trigger_open_late: 1,
              trigger_perfomance_pctg: 100.0,
              trigger_total: 3,
              trigger_responded_in_time: 3,
              trigger_responded_late: 0,
              trigger_open_in_time: 0,
              trigger_open_late: 0,
              overall_performance_pctg: 83.3,
              overall_total: 6,
              overall_responded_in_time: 3,
              overall_responded_late: 0,
              overall_open_in_time: 2,
              overall_open_late: 1,
            },
            "Total" => {
              month_name: "Total",
              non_trigger_performance_pctg: 40.0,
              non_trigger_total: 5,
              non_trigger_responded_in_time: 0,
              non_trigger_responded_late: 0,
              non_trigger_open_in_time: 2,
              non_trigger_open_late: 3,
              trigger_perfomance_pctg: 83.3,
              trigger_total: 6,
              trigger_responded_in_time: 5,
              trigger_responded_late: 1,
              trigger_open_in_time: 0,
              trigger_open_late: 0,
              overall_performance_pctg: 63.6,
              overall_total: 11,
              overall_responded_in_time: 5,
              overall_responded_late: 1,
              overall_open_in_time: 2,
              overall_open_late: 3,
            },
          }
        end

        let(:month_rows) do
          {
            "March" => 7,
            "April" => 8,
            "Total" => 10,
          }
        end

        it "contains the correct monthly figures for March, April and Total" do
          month_rows.each do |month_name, actual_results_row_index|
            expected_month_results = expected_results[month_name]
            actual_results = results[actual_results_row_index]
            expect(actual_results).to eq expected_month_results.values
          end
        end
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
    end

  private

    def create_case(state, month, case_type: :assigned_case)
      k = create case_type, received_date: Date.new(2017, month, 22)
      analyser = double CaseAnalyser
      allow(CaseAnalyser).to receive(:new).with(k).and_return(analyser)
      expect(analyser).to receive(:run)
      expect(analyser).to receive(:result).and_return(state)
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
