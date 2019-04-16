require 'rails_helper'

module ReportingPeriod
  describe YearToDate do
    let(:jan_1)         { Date.new(2018, 1, 1) }
    let(:dec_31)        { Date.new(2018, 12, 31) }

    context '#initialize' do
      it 'works on the first day of the year' do
        Timecop.freeze(jan_1 + 10.hours) do
          year_to_date = described_class.new

          expect(year_to_date.period_start).to eq jan_1
          expect(year_to_date.period_end).to eq jan_1
        end
      end

      it 'works on last day of year' do
        Timecop.freeze(dec_31 + 10.hours) do
          year_to_date = described_class.new

          expect(year_to_date.period_start).to eq jan_1
          expect(year_to_date.period_end).to eq dec_31
        end
      end
    end
  end
end
