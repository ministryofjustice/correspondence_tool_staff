require "rails_helper"

module Stats
  describe R205OffenderSarMonthlyPerformanceReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe ".title" do
      it "returns correct title" do
        expect(described_class.title).to eq "Monthly report"
      end
    end

    describe ".case_analyzer" do
      it "returns correct case_analyzer" do
        expect(described_class.case_analyzer).to eq Stats::OffenderSarAnalyser
      end
    end

    describe ".description" do
      it "returns correct description" do
        expect(described_class.description)
          .to eq "Includes performance data about Offender SAR requests we received and responded to from the beginning of the year by month."
      end
    end

    describe "#case_scope" do
      before do
        create_report_type(abbr: :r205)
      end

      before(:all) do
        Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
          @period_start = 0.business_days.after(Date.new(2018, 12, 20))
          @period_end = 0.business_days.after(Date.new(2018, 12, 31))
          @period_end1 = 0.business_days.after(Date.new(2019, 0o2, 0o1))

          @sar_1 = create :accepted_sar, identifier: "sar-1", received_date: @period_start - 5.hours
          @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: "osar-1", received_date: @period_start - 5.hours

          @sar_2 = create :accepted_sar, identifier: "sar-2", received_date: @period_start + 10.minutes
          @offender_sar_2 = create :offender_sar_case, :closed, identifier: "osar-2", received_date: @period_start + 10.minutes

          @sar_3 = create :accepted_sar, identifier: "sar-3", received_date: @period_start + 5.days
          @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: "osar-3", received_date: @period_start + 5.days

          @sar_4 = create :accepted_sar, identifier: "sar-4", received_date: @period_end + 61.minutes
          @offender_sar_4 = create :offender_sar_case, :ready_to_copy, identifier: "osar-4", received_date: @period_end + 61.minutes

          @offender_sar_complaint = create :offender_sar_complaint, :ready_to_copy, identifier: "ocomp-5", received_date: @period_end + 61.minutes
        end
      end

      it "returns only Offender SAR cases within the selected period" do
        report = described_class.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array([@offender_sar_2, @offender_sar_3, @offender_sar_4])
        expect(report.case_scope).not_to include [@offender_sar_complaint]
      end

      describe "stats values" do
        it "cases in different stages" do
          Timecop.freeze Time.zone.local(2019, 0o1, 30, 12, 0, 0) do
            @responded_in_time = create(
              :offender_sar_case,
              :closed,
            )
            expect(@responded_in_time.responded_in_time?).to be true
          end
          Timecop.freeze Time.zone.local(2019, 0o2, 30, 12, 0, 0) do
            @responded_in_time1 = create(
              :offender_sar_case,
              :closed,
            )
            expect(@responded_in_time1.responded_in_time?).to be true
          end
          Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
            # pending "This fails when the analyzer runs because assign_responder_transitions is nil in business_unit_already_late?"
            late_unassigned_trigger_sar_case = create(
              :offender_sar_case,
              flag_as_high_profile: true,
              identifier: "osar-triggered-1",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_unassigned_trigger_sar_case = create(
              :offender_sar_case,
              flag_as_high_profile: true,
              identifier: "osar-triggered-2",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            responded_late = create(
              :offender_sar_case,
              :closed,
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_unassigned_trigger_sar_case.update!(
              external_deadline: Date.current + 10.days,
            )

            report = described_class.new(
              period_start: @period_start,
              period_end: @period_end1,
            )
            report.run
            results = report.results

            expect(responded_late.responded_late?).to be true
            expect(late_unassigned_trigger_sar_case.already_late?).to be true
            expect(in_time_unassigned_trigger_sar_case.already_late?).to be false
            expect(report.case_scope).to include(late_unassigned_trigger_sar_case)
            expect(report.case_scope).to include(in_time_unassigned_trigger_sar_case)

            expect(results[201_812][:overall_responded_in_time]).to eq(1)
            expect(results[201_812][:overall_responded_late]).to eq(2)
            expect(results[201_812][:overall_open_in_time]).to eq(1)
            expect(results[201_812][:overall_open_late]).to eq(3)
            expect(results[201_812][:overall_performance]).to eq(14.3)

            expect(results[201_901][:overall_responded_in_time]).to eq(1)
            expect(results[201_901][:overall_responded_late]).to eq(0)
            expect(results[201_901][:overall_open_in_time]).to eq(0)
            expect(results[201_901][:overall_open_late]).to eq(0)
            expect(results[201_901][:overall_performance]).to eq(100.0)
          end
        end
      end
    end
  end
end
