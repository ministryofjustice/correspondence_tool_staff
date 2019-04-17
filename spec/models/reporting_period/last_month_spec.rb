require 'rails_helper'

module ReportingPeriod
  describe LastMonth do
    context '#initialize' do
      after do
        Timecop.return
      end

      it 'works on first day of next month' do
        Timecop.freeze(Date.new(2018, 7, 1)) do
          last_month = described_class.new

          expect(last_month.period_start.to_date).to eq Date.new(2018, 6, 1)
          expect(last_month.period_end.to_date).to eq Date.new(2018, 6, 30)
        end
      end
    end
  end
end
