module ReportingPeriod
  class LastMonth < Calculator
    def initialize
      period_start = (Date.today - 1.month).beginning_of_month
      period_end = (Date.today - 1.month).end_of_month

      super(period_start: period_start, period_end: period_end)
    end
  end
end

