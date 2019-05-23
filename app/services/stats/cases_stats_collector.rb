module Stats
  # Designed for use with BaseCasesReport rather than Stats::StatsCollector as
  # Case downloads are already handled by CSVExporter class (and work
  # differently to existing performance reports)
  class CasesStatsCollector
    attr_reader :stats # Duck-type StatsController#stats

    def initialize
      @columns_list = CSVExporter::CSV_COLUMN_HEADINGS
      @stats = []
    end

    def add(kase)
      @stats << CSVExporter.new(kase).to_csv
    end

    # Called by BaseReport#to_csv to create actual spreadsheet data
    # Duck-type StatsCollector#to_csv
    def to_csv(*)
      CaseStatsEnumerator.new(
        @stats,
        @columns_list
      )
    end

    class CaseStatsEnumerator
      include Enumerable

      def initialize(stats, columns_list)
        @stats = stats
        @columns_list = columns_list
      end

      # Lazy enumerator as per Stats::StatsCollector::StatsEnumerator
      def each
        yield @columns_list

        @stats.each do |row|
          yield row
        end
      end
    end
  end
end
