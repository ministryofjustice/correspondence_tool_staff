require 'rails_helper'

module Stats
  describe R105SarMonthlyPerformanceReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(R105SarMonthlyPerformanceReport.title).to eq 'Monthly report'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(R105SarMonthlyPerformanceReport.description)
          .to eq 'Includes performance data about SAR requests we received and responded to from the beginning of the year by month.'
      end
    end

    describe '#case_scope' do
      before do
        create_report_type(abbr: :r105)
      end

      before(:all) do
        @period_start = 0.business_days.after(Date.new(2018, 12, 20))
        @period_end = 0.business_days.after(Date.new(2018, 12, 31))

        @sar_1 = create :accepted_sar, identifier: 'sar-1', creation_time: @period_start - 5.hours
        @foi_1 = create :accepted_case, identifier: 'foi-1', creation_time: @period_start - 5.hours

        @sar_2 = create :accepted_sar, identifier: 'sar-2', creation_time: @period_start + 10.minutes
        @foi_2 = create :accepted_case, identifier: 'foi-2', creation_time: @period_start + 10.minutes

        @sar_3 = create :accepted_sar, identifier: 'sar-3', creation_time: @period_start + 5.days
        @foi_3 = create :accepted_case, identifier: 'foi-3', creation_time: @period_start + 5.days

        @sar_4 = create :accepted_sar, identifier: 'sar-4', creation_time: @period_end  + 61.minutes
        @foi_4 = create :accepted_case, identifier: 'foi-4', creation_time: @period_end  + 61.minutes
      end

      it 'returns only SAR cases within the selected period' do
        report = R105SarMonthlyPerformanceReport.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array( [@sar_2, @sar_3, @sar_4])
      end

      context 'unassigned cases' do
        it 'is calculated as an open case' do
          late_unassigned_trigger_sar_case = create(
            :sar_case,
            :flagged,
            identifier: 'sar-triggered-1',
            creation_time: @period_start + 1.days,
            received_date: @period_start+ 1.days
          )

          in_time_unassigned_trigger_sar_case = create(
            :sar_case,
            :flagged,
            identifier: 'sar-triggered-2',
            creation_time: @period_start + 1.days,
            received_date: @period_start+ 1.days,
          )

          in_time_unassigned_trigger_sar_case.update_attributes(
            external_deadline: Date.current + 10.days
          )

          report = R105SarMonthlyPerformanceReport.new(
            period_start: @period_start,
            period_end: @period_end
          )
          report.run
          results = report.results

          expect(late_unassigned_trigger_sar_case.already_late?).to be true
          expect(in_time_unassigned_trigger_sar_case.already_late?).to be false
          expect(report.case_scope).to include(late_unassigned_trigger_sar_case)
          expect(report.case_scope).to include(in_time_unassigned_trigger_sar_case)
          expect(results[12][:trigger_open_late]).to eq(1)
          expect(results[12][:trigger_open_in_time]).to eq(1)
          expect(results[12][:trigger_total]).to eq(2)
        end
      end
    end
  end
end
