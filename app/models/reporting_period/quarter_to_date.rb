module ReportingPeriod
  class QuarterToDate < Calculator
    def initialize
      period_start = Date.current.beginning_of_quarter
      period_end = Date.current

      super(period_start:, period_end:)
    end
  end
end
