module ReportingPeriod
  class YearToDate < Calculator
    def initialize
      period_start = Date.current.beginning_of_year
      period_end = Date.current

      super(period_start:, period_end:)
    end
  end
end
