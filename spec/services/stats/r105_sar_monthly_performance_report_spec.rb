require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R105SARMonthlyPerformanceReport do
    before(:all) do
      create_report_type(abbr: :r105)

      require Rails.root.join("db/seeders/case_closure_metadata_seeder")
      CaseClosure::MetadataSeeder.seed!

      @period_start = 0.business_days.after(Date.new(2018, 12, 20))
      @period_end = 0.business_days.after(Date.new(2018, 12, 31))

      Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
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

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Monthly report"
      end
    end

    describe ".case_analyzer" do
      it "returns correct case_analyzer" do
        expect(described_class.case_analyzer).to eq Stats::StandardSARAnalyser
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Includes performance data about SAR requests we received and responded to from the beginning of the year by month."
      end
    end

    describe "#report_type" do
      subject { described_class.new(period_start: @period_start, period_end: @period_end).report_type }

      it { is_expected.to eq ReportType.r105 }
    end

    describe "#case_scope" do
      it "returns only SAR cases within the selected period" do
        report = described_class.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array([@sar_2, @sar_3, @sar_4])
      end
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

          report = described_class.new(period_start: @period_start, period_end: @period_end)
          report.run
          results = report.results

          expect(late_unassigned_trigger_sar_case.already_late?).to be true
          expect(in_time_unassigned_trigger_sar_case.already_late?).to be false

          expect(report.case_scope).to include(late_unassigned_trigger_sar_case)
          expect(report.case_scope).to include(in_time_unassigned_trigger_sar_case)

          expect(results[201_812][:non_trigger_open_late]).to eq(2)
          expect(results[201_812][:non_trigger_open_in_time]).to eq(0)
          expect(results[201_812][:non_trigger_performance]).to eq(33.3)
          expect(results[201_812][:non_trigger_total]).to eq(3)

          expect(results[201_812][:trigger_open_late]).to eq(1)
          expect(results[201_812][:trigger_open_in_time]).to eq(1)
          expect(results[201_812][:trigger_performance]).to eq(50)
          expect(results[201_812][:trigger_total]).to eq(2)

          expect(results[201_812][:overall_performance]).to eq(40)
          expect(results[201_812][:overall_total]).to eq(5)
        end
      end
    end

    describe "stopped and extended cases" do
      it "calculates cases which are both stopped and extended in the past" do
        Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
          standard_extended_closed_sar_case = create(
            :closed_sar,
            :extended_deadline_sar,
            identifier: "sar-closed-extended-standard",
            creation_time: @period_start,
            received_date: @period_start + 1.day,
            date_responded: @period_end,
          )

          standard_extended_sar_case = create(
            :sar_case,
            :extended_deadline_sar,
            identifier: "sar-extended-standard",
            creation_time: @period_start + 7.days,
            received_date: @period_start + 7.days,
          )

          standard_stopped_extended_sar_case_1 = create(
            :accepted_sar,
            :stopped,
            :extended_deadline_sar,
            identifier: "sar-stopped-extended-1",
            creation_time: @period_start + 5.days,
          )

          standard_stopped_extended_sar_case_2 = create(
            :accepted_sar,
            :stopped,
            :extended_deadline_sar,
            identifier: "sar-stopped-extended-2",
            creation_time: @period_start + 6.days,
          )

          standard_stopped_extended_sar_case_3 = create(
            :accepted_sar,
            :stopped,
            :extended_deadline_sar,
            identifier: "sar-stopped-extended-3",
            creation_time: @period_start + 6.days,
          )

          trigger_stopped_sar_case = create(
            :sar_case,
            :flagged,
            :stopped,
            identifier: "sar-stopped-triggered",
            creation_time: @period_start + 7.days,
            received_date: @period_start + 7.days,
          )

          trigger_extended_sar_case = create(
            :sar_case,
            :flagged,
            :extended_deadline_sar,
            identifier: "sar-extended-triggered",
            creation_time: @period_start + 7.days,
            received_date: @period_start + 7.days,
          )

          expect(standard_stopped_extended_sar_case_1.stopped?).to be true
          expect(standard_stopped_extended_sar_case_1.active_extension?).to be true
          expect(standard_stopped_extended_sar_case_2.stopped?).to be true
          expect(standard_stopped_extended_sar_case_2.active_extension?).to be true
          expect(standard_stopped_extended_sar_case_3.stopped?).to be true
          expect(standard_stopped_extended_sar_case_3.active_extension?).to be true

          report = described_class.new(period_start: @period_start, period_end: @period_end)
          expect(report.case_scope).to match_array([
            @sar_2, # non-trigger (standard)
            @sar_3, # non-trigger (standard)
            @sar_4, # non-trigger (standard)
            standard_extended_closed_sar_case,
            standard_extended_sar_case,
            standard_stopped_extended_sar_case_1,
            standard_stopped_extended_sar_case_2,
            standard_stopped_extended_sar_case_3,
            trigger_extended_sar_case,
            trigger_stopped_sar_case,
          ])

          report.run
          results = report.results

          expect(results[201_812][:non_trigger_sar_extensions]).to eq(2) # Excludes standard_stopped_extended_sar_case_1 and standard_stopped_extended_sar_case_2
          expect(results[201_812][:non_trigger_stopped]).to eq(3)
          expect(results[201_812][:non_trigger_total]).to eq(5) # Pause/Stopped cases excluded from total

          expect(results[201_812][:trigger_sar_extensions]).to eq(1)
          expect(results[201_812][:trigger_stopped]).to eq(1)
          expect(results[201_812][:trigger_total]).to eq(1) # Pause/Stopped cases excluded from total

          expect(results[201_812][:overall_sar_extensions]).to eq(3) # Exlcludes standard_stopped_extended_sar_case_1 and standard_stopped_extended_sar_case_2
          expect(results[201_812][:overall_stopped]).to eq(4)
          expect(results[201_812][:overall_total]).to eq(6) # Pause/Stopped cases excluded from total
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
