module ReportingPeriod
  class DateInterval < Calculator
    def initialize(period_start:, period_end:)
      super(period_start: period_start, period_end: period_end)
    end
  end
end

