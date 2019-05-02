module Stats
  # @note: Mohammed Seedat: 2019-05-01
  #
  # Case reports differ from existing Performance/Stats reports as they
  # output an unknown number of rows. This is a transition class that
  # introduces the Closed Cases report ()handled directly by CSVExporter at
  # present) to the Stats system which assumes there are appropriate
  # ReportTypes available. Going forward Open Cases/My Open Cases should be
  # generated this way to so that the full Excel reporting capabilities
  # can be taken advatage of
  class BaseCasesReport < BaseReport
    class << self
      def xlsx?
        false
      end
    end

    def initialize(**options)
      super(**options)

      @stats = CasesStatsCollector.new
    end

    def run
      #.cases_for_period(@period_start, @period_end)
      case_scope
        .each { |kase| @stats.add(kase) }
    end

    def self.persist_results?
      false
    end
  end
end
