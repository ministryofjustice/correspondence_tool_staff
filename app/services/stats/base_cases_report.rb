module Stats
  class BaseCasesReport < BaseReport
    class << self
      def xlsx?
        false
      end
    end

    def initialize(user:, period_start: nil, period_end: nil)
      super(period_start, period_end)

      @user = user
      @stats = CasesStatsCollector.new
    end

    def run
      #.cases_for_period(@period_start, @period_end)
      case_scope
        .each { |kase| @stats.add(kase) }
    end

    def persist_results?
      false
    end
  end
end
