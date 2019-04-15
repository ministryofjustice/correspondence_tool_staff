module ReportingPeriod
  class QuarterToDate < Calculator
    def initialize
      period_start = Date.today.beginning_of_quarter
      period_end = Date.today

      super(period_start: period_start, period_end: period_end)
    end
  end
end
