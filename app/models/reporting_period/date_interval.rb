module ReportingPeriod
  class DateInterval < Calculator
    def initialize(period_start:, period_end:)
      unless period_start.is_a?(Date) && period_end.is_a?(Date)
        raise ArgumentError.new 'period_start and period_end must be Dates'
      end

      super(period_start: period_start, period_end: period_end)
    end
  end
end

