require 'rails_helper'

module Stats
  describe ReportingPeriodCalculator do

    let(:jan_1)         { Date.new(2018, 1, 1) }
    let(:feb_1)         { Date.new(2018, 2, 1) }
    let(:apr_1)         { Date.new(2018, 4, 1) }
    let(:apr_30)        { Date.new(2018, 4, 30 ) }
    let(:jun_1)         { Date.new(2018, 6, 1) }
    let(:jun_30)        { Date.new(2018, 6, 30) }
    let(:jul_1)         { Date.new(2018, 7, 1) }
    let(:dec_31)        { Date.new(2018, 12, 31) }


    context 'intialization errors' do
      context 'no parameters passed' do
        it 'raises' do
          expect {
            described_class.new
          }.to raise_error ArgumentError, 'Period start and end must both be specified as Dates'
        end
      end

      context 'period start and end not passed as date objects' do
        it 'raises' do
          expect {
            described_class.new(period_start: Time.now, period_end: Time.now)
          }.to raise_error ArgumentError, 'Period start and end must both be specified as Dates'
        end
      end

      context 'invalid period name specified' do
        it 'raises' do
          expect {
            described_class.new(period_name: :last_year)
          }.to raise_error ArgumentError, 'Invalid period name specified'
        end
      end
    end

    context 'specify period with dates' do
      it 'instantiates with the specified dates' do
        rpc = ReportingPeriodCalculator.new(period_start: feb_1, period_end: apr_30)
        expect(rpc.period_start).to eq feb_1
        expect(rpc.period_end).to eq apr_30
      end
    end

    context 'specify period with period names' do
      context :year_to_date do
        it 'works on the first day of the year' do
          Timecop.freeze(jan_1 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :year_to_date)
            expect(rpc.period_start).to eq jan_1
            expect(rpc.period_end).to eq jan_1
          end
        end

        it 'works on last day of year' do
          Timecop.freeze(dec_31 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :year_to_date)
            expect(rpc.period_start).to eq jan_1
            expect(rpc.period_end).to eq dec_31
          end
        end
      end

      context 'quarter_to_date' do
        it 'works of first day of quarter' do
          Timecop.freeze(apr_1 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :quarter_to_date)
            expect(rpc.period_start).to eq apr_1
            expect(rpc.period_end).to eq apr_1
          end
        end

        it 'works of last day of quarter' do
          Timecop.freeze(jun_30 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :quarter_to_date)
            expect(rpc.period_start).to eq apr_1
            expect(rpc.period_end).to eq jun_30
          end
        end
      end

      context 'last_quarter' do
        it 'works on first day of next quarter' do
          Timecop.freeze(jul_1 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :last_quarter)
            expect(rpc.period_start).to eq apr_1
            expect(rpc.period_end).to eq jun_30
          end
        end
      end

      context 'last_month' do
        it 'works on first day of next month' do
          Timecop.freeze(jul_1 + 10.hours) do
            rpc = ReportingPeriodCalculator.new(period_name: :last_month)
            expect(rpc.period_start).to eq jun_1
            expect(rpc.period_end).to eq jun_30
          end
        end
      end
    end

    describe '#to_s' do
      it 'displays dates in human readable form' do
        rpc = ReportingPeriodCalculator.new(period_start: feb_1, period_end: apr_30)
        expect(rpc.to_s).to eq '1 Feb 2018 to 30 Apr 2018'
      end
    end

  end
end
