module Stats
  # Given a +columns_list+ will output all given Cases in +@stats+.
  # Currently used to generate Closed Cases only. Does not inherit from
  # StatsController due to the way Closed Cases require output
  # of an unknown number of rows and field calculations are handled
  # by the CSVExporter class, which is also used to generate
  # All Open Cases and My Open Cases. Consumers of this class are to
  # treat it like a StatsController
  class CasesStatsCollector
    attr_reader :stats # Duck-type StatsController#stats

    # Assume CSVExporter will ensure the @column_list and
    # values set for @stats will be consistent
    def initialize
      @columns_list = CSVExporter::CSV_COLUMN_HEADINGS
      @stats = {}
    end

    def add(kase)
      @stats[kase.number] = CSVExporter.new(kase).to_csv
    end

    # Called by BaseReport#to_csv to create actual spreadsheet data
    # duck-type StatsCollector#to_csv therefore ignores
    # +first_column_header+ and +superheadings+ parameters
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
        @_stats ||= @stats.to_enum

        yield @columns_list

        @_stats.each do |row|
          yield row.second
        end
      end
    end
  end
end
