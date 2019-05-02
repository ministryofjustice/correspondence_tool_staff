module Stats
  class BaseReport

    # These are the current RAG (red-amber-green) thresholds for each report type
    # obviously anything above the 'amber' threshold is 'green'
    RAG_THRESHOLDS_FOI = { red: 85, amber: 90 }
    RAG_THRESHOLDS_SAR = { red: 80, amber: 85 }

    attr_reader :period_start, :period_end, :user

    def initialize(**options)
      raise 'Cannot instantiate Stats::BaseReport - use derived class instead' if self.class == BaseReport

      @stats = nil                        # implement @stats as an instance of StatsCollector in derived class
      @first_column_heading = 'Teams'     # override in derived class if other heading required
      @superheadings = []                 # override in derived class if extra heading lines required in CSV

      @reporting_period = ReportingPeriod::Calculator.build(
        period_start: options[:period_start],
        period_end: options[:period_end],
        period_name: default_reporting_period
      )

      @user = options[:user] # Some reports depend on the current user context e.g. Closed Cases
      @period_start = @reporting_period.period_start
      @period_end = @reporting_period.period_end
    end

    def rag_thresholds
      report_type.foi ? RAG_THRESHOLDS_FOI : RAG_THRESHOLDS_SAR
    end

    def rag_rating(value)
      if value < rag_thresholds[:red]
        :red
      elsif value < rag_thresholds[:amber]
        :amber
      else
        :green
      end
    end

    def header_cell row_index, item
      case row_index
      when 0
        OpenStruct.new value: item
      when 1
        OpenStruct.new value: item, rag_rating: :blue
      else
        OpenStruct.new value: item, rag_rating: :grey
      end
    end

    def self.title
      raise "#{self} doesn't implement .title method"
    end

    def self.description
      raise "#{self} doesn't implement .description method"
    end

    def self.report_type
      raise 'This method should be defined in the child class'
    end

    def default_reporting_period
      report_type.default_reporting_period
    end

    def results
      @stats.stats
    end

    # Called by the selected Report#generate_csv method.
    # Converts +@stats+ to an Array of hash-like OpenStructs for output.
    #
    # Example output:
    # [
    #   [ #<OpenStruct value="Number">, #<OpenStruct value="Current state">],
    #   [ #<OpenStruct value="190319002">, #<OpenStruct value="Open">],
    #   [ #<OpenStruct value="828919910">, #<OpenStruct value="Closed"> ]
    # ]
    def to_csv
      # +csv+ will contain all the raw data making up this spreadsheet
      csv = @stats.to_csv(
        first_column_header: @first_column_heading,
        superheadings: @superheadings
      )

      csv.map do |csv_row|
        csv_row.map { |item| OpenStruct.new(value: item) }
      end
    end

    def reporting_period
      @reporting_period.to_s
    end

    # By default all generated Reports are persisted to the database.
    # This would be detrimental for result sets that are known to be very
    # large e.g. Closed Cases report
    def self.persist_results?
      true
    end

    def persist_results?
      self.class.persist_results?
    end
  end
end
