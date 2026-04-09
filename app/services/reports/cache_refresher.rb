module Reports
  class CacheRefresher
    # Refreshes the JSON cache for all supported report types.
    # - Iterates ReportType.standard (downloadable standard reports) and also R900
    # - Runs each report service using its default reporting period
    # - Persists results JSON to ReportsCache
    # - Logs per-report success/failure
    # - Continues on error (isolation)
    # - Idempotent: creates a new cache row per run; previous rows retained for history
    def self.call(logger: Rails.logger)
      new(logger:).call
    end

    def initialize(logger: Rails.logger)
      @logger = logger
    end

    def call
      started = Time.current
      logger.info("Reports::CacheRefresher started at #{started}")

      successes = 0
      failures = 0

      report_types_to_refresh.each do |report_type|
        refresh_one(report_type)
        successes += 1
      rescue StandardError => e
        failures += 1
        logger.error("Failed to refresh report cache for #{report_type.abbr} (#{report_type.class_name}): #{e.class} - #{e.message}")
        logger.error(e.backtrace.join("\n")) if Rails.env.development? || Rails.env.test?
        next
      end

      duration = ((Time.current - started) * 1000).round(1)
      logger.info("Reports::CacheRefresher finished in #{duration}ms - successes=#{successes} failures=#{failures}")

      { successes:, failures:, duration_ms: duration }
    end

  private

    attr_reader :logger

    # Build the list of report types to refresh. This includes all standard reports
    # and also explicitly includes R900 (Cases report) which is not a standard report
    # type but should be cached.
    def report_types_to_refresh
      types = ReportType.standard.to_a
      begin
        r900 = ReportType.r900
        types << r900 unless types.any? { |rt| rt.abbr == "R900" }
      rescue ActiveRecord::RecordNotFound
        # If R900 is not present in this environment, just skip it.
      end
      types
    end

    def refresh_one(report_type)
      service_class = report_type.class_constant
      service = service_class.new

      # Some reports are ETL/background-job based and don't return data immediately.
      # Skip caching those; they are handled via their own pipelines.
      service.run
      if service.background_job? || !service.persist_results?
        logger.info("Skipping cache for #{report_type.abbr} (background job or non-persistent)")
        return
      end

      data = service.results
      ReportsCache.store!(report_type: report_type.abbr, data: data)
      logger.info("Cached report #{report_type.abbr} successfully (#{data.class.name})")
    end
  end
end
