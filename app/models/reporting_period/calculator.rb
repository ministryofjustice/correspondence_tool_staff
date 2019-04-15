module ReportingPeriod
  class Calculator
    attr_reader :period_start, :period_end

    def initialize(period_start: nil, period_end: nil)
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
