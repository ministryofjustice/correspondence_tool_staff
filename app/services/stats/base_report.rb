module Stats
  class BaseReport

    attr_reader :period_start, :period_end

    def initialize(period_start = nil, period_end = nil)
      raise "Cannot instantiate Stats::BaseReport - use derived class instead" if self.class == BaseReport
      @stats = nil                        # implement @stats as an instance of StatsCollector in derived class
      @first_column_heading = 'Teams'     # override in derived class if other heading required
      @superheadings = []                 # override in derived class if extra heading lines required in CSV
      if period_start.nil? && period_end.nil?
        @reporting_period = ReportingPeriodCalculator.new(period_name: default_reporting_period)
      else
        @reporting_period = ReportingPeriodCalculator.new(period_start: period_start, period_end: period_end)
      end
      @period_start = @reporting_period.period_start
      @period_end = @reporting_period.period_end
    end

    def self.title
      raise "#{self} doesn't implement .title method"
    end

    def self.description
      raise "#{self} doesn't implement .description method"
    end


    def self.report_type
      puts self.class.to_s
      raise 'This method shuld be defined in the child class'
    end


    def default_reporting_period
      report_type.default_reporting_period
    end


    def results
      @stats.stats
    end

    def to_csv
      @stats.to_csv(first_column_header: @first_column_heading,
                    superheadings:       @superheadings)
    end

    def reporting_period
      raise "Period start/end not specified" if @period_start.nil? || @period_end.nil?
      "#{@period_start.strftime(Settings.default_date_format)} to #{@period_end.strftime(Settings.default_date_format)}"
    end
  end
end
