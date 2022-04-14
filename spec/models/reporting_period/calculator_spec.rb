require 'rails_helper'

module ReportingPeriod
  describe Calculator do
    describe '#initialize' do
      context 'with invalid parameters' do
        it 'raises exception' do
          expect {
            described_class.new(
              period_start: "1st January 2014",
              period_end: "2019-02-02"
            )
          }.to raise_error(
            ArgumentError,
            'period_start and period_end must be a Date type'
          )
        end
      end

      context 'with valid parameters' do
        it 'sets period_start and period_end with Date values' do
          calculator = described_class.new(
            period_start: Date.yesterday,
            period_end: Date.tomorrow
          )

          expect(calculator.period_start).to be_a Time
          expect(calculator.period_end).to be_a Time
        end

        it 'sets period_start and period_end with Time or DateTime values' do
          calculator = described_class.new(
            period_start: DateTime.yesterday,
            period_end: Time.zone.now
          )

          expect(calculator.period_start).to be_a Time
          expect(calculator.period_end).to be_a Time
        end

        it 'sets inclusive Times' do
          calculator = described_class.new(
            period_start: Date.new(2018, 2, 1),
            period_end: Date.new(2018, 4, 30)
          )

          format = '%F %H:%M' # Ignore timezone for testing purposes
          expect(calculator.period_start.strftime(format)).to eq '2018-02-01 00:00'
          expect(calculator.period_end.strftime(format)).to eq '2018-04-30 23:59'
        end
      end
    end

    describe '#to_s' do
      it 'displays dates in human readable form' do
        calculator = described_class.new(
          period_start: Date.new(2018, 2, 1),
          period_end: Date.new(2018, 4, 30)
        )

        expect(calculator.to_s).to eq '1 Feb 2018 to 30 Apr 2018'
      end
    end

    describe '#build' do
      it 'instantiates a named date calculator' do
        date_calculator = described_class.build(period_name: 'last_quarter')

        expect(date_calculator).to be_a ReportingPeriod::LastQuarter
      end

      it 'instantiates a DateInteval without a named date calculator' do
        date_calculator = described_class.build(
          period_start: DateTime.yesterday,
          period_end: DateTime.tomorrow,
          period_name: ''
        )

        expect(date_calculator).to be_a ReportingPeriod::DateInterval
      end
    end
  end
end
