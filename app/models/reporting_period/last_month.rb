module ReportingPeriod
  class LastMonth < Calculator
    def initialize
      period_start = (Date.current - 1.month).beginning_of_month
      period_end = (Date.current - 1.month).end_of_month

      super(period_start:, period_end:)
    end
  end
end
