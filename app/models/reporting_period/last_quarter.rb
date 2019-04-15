module ReportingPeriod
  class LastQuarter < Calculator
    def initialize
      period_start = (Date.today - 3.months).beginning_of_quarter
      period_end = (Date.today - 3.months).end_of_quarter

      super(period_start: period_start, period_end: period_end)
    end
  end
end
