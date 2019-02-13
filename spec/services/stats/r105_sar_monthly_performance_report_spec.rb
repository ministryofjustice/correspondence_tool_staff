require 'rails_helper'

module Stats
  describe R105SarMonthlyPerformanceReport do
    Timecop.freeze(Time.local(2019, 1, 1)) do

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

        before(:each) do
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
          report = R105SarMonthlyPerformanceReport.new(@period_start, @period_end)
          expect(report.case_scope).to match_array( [ @sar_2, @sar_3 ])
        end
      end
    end
  end
end
