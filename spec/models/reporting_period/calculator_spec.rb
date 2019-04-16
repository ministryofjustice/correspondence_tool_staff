require 'rails_helper'

module ReportingPeriod
  describe Calculator do
    let(:feb_1)         { Date.new(2018, 2, 1) }
    let(:apr_30)        { Date.new(2018, 4, 30 ) }

    describe '#initialize' do
      context 'with invalid parameters' do
        it 'raises' do
          expect {
            described_class.new(period_start: Time.now, period_end: "2019-02-02")
          }.to raise_error ArgumentError, 'period_start and period_end must be Dates'
        end
      end

      context 'with valid parameters' do
        it 'sets period_start and period_end' do
          rpc = Calculator.new(period_start: feb_1, period_end: apr_30)
          expect(rpc.period_start).to eq feb_1
          expect(rpc.period_end).to eq apr_30
        end
      end
    end

    describe '#to_s' do
      it 'displays dates in human readable form' do
        rpc = Calculator.new(period_start: feb_1, period_end: apr_30)
        expect(rpc.to_s).to eq '1 Feb 2018 to 30 Apr 2018'
      end
    end
  end
end
