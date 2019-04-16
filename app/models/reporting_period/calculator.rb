module ReportingPeriod
  class Calculator
    attr_reader :period_start, :period_end

    # @note +period_start+ and +period_end+ are always converted to Time
    #   to ensure both dates are inclusive of that whole day for accurate
    #   up-to-date reporting purposes. There is no requirement for
    #   non-inclusive dates at present
    def initialize(period_start:, period_end:)
      unless valid_date?(period_start) && valid_date?(period_end)
        raise ArgumentError.new 'period_start and period_end must be a Date type'
      end

      @period_start = period_start.beginning_of_day
      @period_end = period_end.end_of_day
    end

    def to_s
      mask = Settings.default_date_format
      "#{@period_start.strftime(mask)} to #{@period_end.strftime(mask)}"
    end

    def self.build(period_start: nil, period_end: nil, period_name: '')
      if period_name.present?
        "ReportingPeriod::#{period_name.to_s.camelize}".constantize.new
      else
        ReportingPeriod::DateInterval.new(
          period_start: period_start,
          period_end: period_end
        )
      end
    end

    private

    def valid_date?(date)
      date.methods.include?(:strftime)
    end
  end
end
