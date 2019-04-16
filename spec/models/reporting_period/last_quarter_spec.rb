require 'rails_helper'

module ReportingPeriod
  describe LastQuarter do
    let(:apr_1)         { Date.new(2018, 4, 1) }
    let(:jun_30)        { Date.new(2018, 6, 30) }
    let(:jul_1)         { Date.new(2018, 7, 1) }

    context '#initialize' do
      it 'works on first day of next quarter' do
        Timecop.freeze(jul_1 + 10.hours) do
          last_quarter = described_class.new

          expect(last_quarter.period_start).to eq apr_1
          expect(last_quarter.period_end).to eq jun_30
        end
      end
    end
  end
end
