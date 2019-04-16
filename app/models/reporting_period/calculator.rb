module ReportingPeriod
  class Calculator
    attr_reader :period_start, :period_end

    def initialize(period_start:, period_end:)
      unless period_start.is_a?(Date) && period_end.is_a?(Date)
        raise ArgumentError.new 'period_start and period_end must be Dates'
      end

      @period_start = period_start
      @period_end = period_end
    end

    def to_s
      mask = Settings.default_date_format
      "#{@period_start.strftime(mask)} to #{@period_end.strftime(mask)}"
    end

    def self.build(period_name)
      "ReportingPeriod::#{period_name.to_s.camelize}".constantize.new
    end
  end
end
