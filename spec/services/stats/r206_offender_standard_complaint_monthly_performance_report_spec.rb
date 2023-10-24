require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
module Stats
  describe R206OffenderStandardComplaintMonthlyPerformanceReport do
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
          .to eq "Includes performance data about standard Offender complaint requests we received and responded to from the beginning of the year by month."
      end
    end

    describe "#case_scope" do
      before do
        create_report_type(abbr: :r206)
      end

      before(:all) do
        Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
          @period_start = Date.new(2019, 4, 0o1) = 0.working.days
          @period_end = Date.new(2019, 6, 0o1) + 0.working.days

          @sar_1 = create :accepted_sar, identifier: "sar-1", received_date: @period_start - 5.hours
          @ostandard_complaint_1 = create :offender_sar_complaint, :waiting_for_data,
                                          complaint_type: "standard_complaint",
                                          identifier: "ostandard_complaint-1",
                                          received_date: @period_start - 5.hours

          @sar_2 = create :accepted_sar, identifier: "sar-2", received_date: @period_start + 10.minutes
          @ostandard_complaint_2 = create :offender_sar_complaint, :closed,
                                          complaint_type: "standard_complaint",
                                          identifier: "ostandard_complaint-2",
                                          received_date: @period_start + 10.minutes

          @sar_3 = create :accepted_sar, identifier: "sar-3", received_date: @period_start + 5.days
          @ostandard_complaint_3 = create :offender_sar_complaint, :data_to_be_requested,
                                          complaint_type: "standard_complaint",
                                          identifier: "ostandard_complaint-3",
                                          received_date: @period_start + 5.days

          @sar_4 = create :accepted_sar, identifier: "sar-4", received_date: @period_start + 61.minutes
          @ostandard_complaint_4 = create :offender_sar_complaint, :ready_to_copy,
                                          complaint_type: "standard_complaint",
                                          identifier: "ostandard_complaint-4",
                                          received_date: @period_start + 61.minutes
        end
      end

      after(:all) do
        DbHousekeeping.clean(seed: true)
      end

      it "returns only standard Offender SAR complaints within the selected period" do
        report = described_class.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array([@ostandard_complaint_2, @ostandard_complaint_3, @ostandard_complaint_4])
      end

      describe "stats values" do
        it "cases in different stages" do
          responded_late = nil
          Timecop.freeze Time.zone.local(2019, 0o5, 20, 12, 0, 0) do
            responded_late = create(
              :offender_sar_complaint,
              :closed,
              complaint_type: "standard_complaint",
            )
          end
          Timecop.freeze Time.zone.local(2019, 6, 30, 12, 0, 0) do
            late_open_case = create(
              :offender_sar_complaint,
              complaint_type: "standard_complaint",
              identifier: "oscomplaint-late-1",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_open_case = create(
              :offender_sar_complaint,
              complaint_type: "standard_complaint",
              identifier: "oscomplaint-in-time-2",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            responded_in_time = create(
              :offender_sar_complaint,
              :closed,
              complaint_type: "standard_complaint",
              creation_time: @period_start + 1.day,
              received_date: @period_start + 1.day,
            )

            in_time_open_case.update!(
              external_deadline: Date.current + 10.days,
            )

            responded_late.date_responded = Date.current - 10.days
            responded_late.save!

            late_open_case.external_deadline = late_open_case.received_date + 20.days
            late_open_case.save!

            report = described_class.new(
              period_start: @period_start,
              period_end: @period_end,
            )
            report.run
            results = report.results

            expect(responded_in_time.responded_in_time?).to be true
            expect(responded_late.responded_late?).to be true
            expect(late_open_case.already_late?).to be true
            expect(in_time_open_case.already_late?).to be false
            expect(report.case_scope).to include(late_open_case)
            expect(report.case_scope).to include(in_time_open_case)

            expect(results[201_904][:overall_responded_in_time]).to eq(2)
            expect(results[201_904][:overall_responded_late]).to eq(1)
            expect(results[201_904][:overall_open_in_time]).to eq(3)
            expect(results[201_904][:overall_open_late]).to eq(1)
            expect(results[201_904][:overall_performance]).to eq(28.6)
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
