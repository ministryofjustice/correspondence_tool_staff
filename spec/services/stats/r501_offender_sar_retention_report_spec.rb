require "rails_helper"

module Stats
  describe R501OffenderSarRetentionReport do
    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Retention report"
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Shows cases whose last action was between the selected dates"
      end
    end

    describe "reporting" do
      let(:period_start) { Date.new(2023, 7, 1) }
      let(:period_end) { Date.new(2023, 7, 31) }
      let(:closed_offender_sar) do
        create(:offender_sar_case, :closed)
      end
      let(:closed_offender_sar1) do
        create(:offender_sar_case, :closed)
      end
      let(:closed_offender_sar2) do
        create(:offender_sar_case, :closed)
      end

      let(:report) do
        described_class.new(
          period_start:,
          period_end:,
        )
      end

      before do
        create_report_type(abbr: :r501)

        Timecop.travel(period_end - 1.hour) do
          create :closed_sar, identifier: "closed sar"
          create :closed_case, identifier: "closed foi"
          create :offender_sar_complaint, :closed, original_case: closed_offender_sar, identifier: "offender sar complaint"
        end
      end

      describe "#case_scope" do
        it "returns correct cases" do
          Timecop.travel(period_start - 1.hour) do
            closed_offender_sar2
          end

          Timecop.travel(period_end - 1.hour) do
            expected = [closed_offender_sar.name, closed_offender_sar1.name]
            expect(report.case_scope.map(&:name)).to match_array(expected)
          end
        end
      end

      describe "#run" do
        before do
          Timecop.travel(period_end - 1.hour) { closed_offender_sar }
          report.run
        end

        it "does not persist results" do
          expect(report.persist_results?).to eq false
        end

        it "creates data for csv" do
          expect(csv_lines).to eq report.results
        end

        it "puts header in CSV" do
          expect(csv_lines.first).to eq described_class::CSV_COLUMN_HEADINGS
        end

        it "puts case details in CSV" do
          expect(csv_lines.second).to eq report.process(closed_offender_sar)
        end
      end

      def csv_lines
        report.to_csv.map { |row| row.map(&:value) }
      end
    end
  end
end
