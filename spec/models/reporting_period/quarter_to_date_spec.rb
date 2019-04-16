require 'rails_helper'

module ReportingPeriod
  describe QuarterToDate do
    let(:apr_1)         { Date.new(2018, 4, 1) }
    let(:jun_30)        { Date.new(2018, 6, 30) }

    context '#initialize' do
      it 'works of first day of quarter' do
        Timecop.freeze(apr_1 + 10.hours) do
          quarter_to_date = described_class.new
          expect(quarter_to_date.period_start).to eq apr_1
          expect(quarter_to_date.period_end).to eq apr_1
        end
      end

      it 'works of last day of quarter' do
        Timecop.freeze(jun_30 + 10.hours) do
          quarter_to_date = described_class.new
          expect(quarter_to_date.period_start).to eq apr_1
          expect(quarter_to_date.period_end).to eq jun_30
        end
      end
    end
  end
end
