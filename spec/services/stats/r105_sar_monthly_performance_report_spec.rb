require "rails_helper"

module Stats
  describe R105SarMonthlyPerformanceReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Monthly report"
      end
    end

    describe ".case_analyzer" do
      it "returns correct case_analyzer" do
        expect(R005MonthlyPerformanceReport.case_analyzer).to eq Stats::CaseAnalyser
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Includes performance data about SAR requests we received and responded to from the beginning of the year by month."
      end
    end

    describe "#case_scope" do
      before do
        create_report_type(abbr: :r105)
      end

      before(:all) do
        require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")
        CaseClosure::MetadataSeeder.seed!

        Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
          @period_start = 0.business_days.after(Date.new(2018, 12, 20))
          @period_end = 0.business_days.after(Date.new(2018, 12, 31))

          @sar_1 = create :accepted_sar, identifier: "sar-1", creation_time: @period_start - 5.hours
          @foi_1 = create :accepted_case, identifier: "foi-1", creation_time: @period_start - 5.hours

          @sar_2 = create :accepted_sar, identifier: "sar-2", creation_time: @period_start + 10.minutes
          @foi_2 = create :accepted_case, identifier: "foi-2", creation_time: @period_start + 10.minutes

          @sar_3 = create :accepted_sar, identifier: "sar-3", creation_time: @period_start + 5.days
          @foi_3 = create :accepted_case, identifier: "foi-3", creation_time: @period_start + 5.days

          @sar_4 = create :closed_sar, identifier: "sar-4", creation_time: @period_start,
                                       received_date: @period_start + 1.day, date_responded: @period_end
          @foi_4 = create :closed_case, identifier: "foi-4", creation_time: @period_start

          @sar_5 = create :closed_sar, :clarification_required, identifier: "sar-tmm", creation_time: @period_start,
                                                                received_date: @period_start + 1.day, date_responded: @period_end
        end
      end

      it "returns only SAR cases within the selected period" do
        report = described_class.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array([@sar_2, @sar_3, @sar_4])
      end

      describe "unassigned cases" do
        it "is calculated as an open case" do
          Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
            late_unassigned_trigger_sar_case = create(
              :sar_case,
              :flagged,
              identifier: "sar-triggered-1",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_unassigned_trigger_sar_case = create(
              :sar_case,
              :flagged,
              identifier: "sar-triggered-2",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_unassigned_trigger_sar_case.update!(
              external_deadline: Date.current + 10.days,
            )

            report = described_class.new(
              period_start: @period_start,
              period_end: @period_end,
            )
            report.run
            results = report.results
            expect(late_unassigned_trigger_sar_case.already_late?).to be true
            expect(in_time_unassigned_trigger_sar_case.already_late?).to be false
            expect(report.case_scope).to include(late_unassigned_trigger_sar_case)
            expect(report.case_scope).to include(in_time_unassigned_trigger_sar_case)
            expect(results[201_812][:non_trigger_open_late]).to eq(2)
            expect(results[201_812][:non_trigger_performance]).to eq(33.3)
            expect(results[201_812][:trigger_open_late]).to eq(1)
            expect(results[201_812][:trigger_open_in_time]).to eq(1)
            expect(results[201_812][:trigger_performance]).to eq(50)
            expect(results[201_812][:overall_performance]).to eq(40)
          end
        end
      end
    end
  end
end
