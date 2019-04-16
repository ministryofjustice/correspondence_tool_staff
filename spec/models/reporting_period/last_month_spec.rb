require 'rails_helper'

module ReportingPeriod
  describe LastMonth do
    let(:jun_1)         { Date.new(2018, 6, 1) }
    let(:jun_30)        { Date.new(2018, 6, 30) }
    let(:jul_1)         { Date.new(2018, 7, 1) }

    context '#initialize' do
      it 'works on first day of next month' do
        Timecop.freeze(jul_1 + 10.hours) do
          last_month = described_class.new

          expect(last_month.period_start).to eq jun_1
          expect(last_month.period_end).to eq jun_30
        end
      end
    end
  end
end
