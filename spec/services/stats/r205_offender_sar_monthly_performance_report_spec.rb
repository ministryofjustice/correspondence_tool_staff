require 'rails_helper'

module Stats
  describe R205OffenderSarMonthlyPerformanceReport do
    after(:all) { DbHousekeeping.clean(seed: true) }

    describe '.title' do
      it 'returns correct title' do
        expect(described_class.title).to eq 'Monthly report'
      end
    end

    describe '.description' do
      it 'returns correct description' do
        expect(described_class.description)
          .to eq 'Includes performance data about Offender SAR requests we received and responded to from the beginning of the year by month.'
      end
    end

    describe '#case_scope' do
      before do
        create_report_type(abbr: :r205)
      end

      before(:all) do
        @period_start = 0.business_days.after(Date.new(2018, 12, 20))
        @period_end = 0.business_days.after(Date.new(2018, 12, 31))

        @sar_1 = create :accepted_sar, identifier: 'sar-1', creation_time: @period_start - 5.hours
        @offender_sar_1 = create :offender_sar_case, :waiting_for_data, identifier: 'osar-1', creation_time: @period_start - 5.hours

        @sar_2 = create :accepted_sar, identifier: 'sar-2', creation_time: @period_start + 10.minutes
        @offender_sar_2 = create :offender_sar_case, :closed, identifier: 'osar-2', creation_time: @period_start + 10.minutes

        @sar_3 = create :accepted_sar, identifier: 'sar-3', creation_time: @period_start + 5.days
        @offender_sar_3 = create :offender_sar_case, :data_to_be_requested, identifier: 'osar-3', creation_time: @period_start + 5.days

        @sar_4 = create :accepted_sar, identifier: 'sar-4', creation_time: @period_end  + 61.minutes
        @offender_sar_4 = create :offender_sar_case, :ready_to_copy, identifier: 'osar-4', creation_time: @period_end  + 61.minutes
      end

      it 'returns only Offender SAR cases within the selected period' do
        report = described_class.new(period_start: @period_start, period_end: @period_end)
        expect(report.case_scope).to match_array( [@offender_sar_2, @offender_sar_3, @offender_sar_4])
      end

      # @todo(Mohammed Seedat): Business Rules for 'in time' require clarification
      context 'unassigned cases' do
        xit 'is calculated as an open case' do
          late_unassigned_trigger_sar_case = create(
            :offender_sar_case,
            flag_as_high_profile: true,
            identifier: 'osar-triggered-1',
            creation_time: @period_start + 1.days,
            received_date: @period_start+ 1.days
          )

          in_time_unassigned_trigger_sar_case = create(
            :offender_sar_case,
            flag_as_high_profile: true,
            identifier: 'osar-triggered-2',
            creation_time: @period_start + 1.days,
            received_date: @period_start+ 1.days,
          )

          in_time_unassigned_trigger_sar_case.update_attributes(
            external_deadline: Date.current + 10.days
          )

          report = described_class.new(
            period_start: @period_start,
            period_end: @period_end
          )
          report.run

          expect(late_unassigned_trigger_sar_case.already_late?).to be true
          expect(in_time_unassigned_trigger_sar_case.already_late?).to be false
          expect(report.case_scope).to include(late_unassigned_trigger_sar_case)
          expect(report.case_scope).to include(in_time_unassigned_trigger_sar_case)
        end
      end
    end
  end
end
