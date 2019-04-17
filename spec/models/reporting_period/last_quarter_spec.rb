require 'rails_helper'

module ReportingPeriod
  describe LastQuarter do
    context '#initialize' do
      it 'works on first day of next quarter' do
        date = Date.new(2018, 7, 1)
        expected_start = Date.new(2018, 4, 1)
        expected_end = Date.new(2018, 6, 30)

        Timecop.freeze(date) do
          last_quarter = described_class.new

          expect(last_quarter.period_start.to_date).to eq expected_start
          expect(last_quarter.period_end.to_date).to eq expected_end
        end
      end
    end
  end
end
