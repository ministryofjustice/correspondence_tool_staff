require 'rails_helper'

module ReportingPeriod
  describe LastQuarter do
    context '#initialize' do
      after do
        Timecop.return
      end

      it 'works on first day of next quarter' do
        Timecop.freeze(Date.new(2018, 7, 1)) do
          last_quarter = described_class.new

          expect(last_quarter.period_start.to_date).to eq Date.new(2018, 4, 1)
          expect(last_quarter.period_end.to_date).to eq Date.new(2018, 6, 30)
        end
      end
    end
  end
end
