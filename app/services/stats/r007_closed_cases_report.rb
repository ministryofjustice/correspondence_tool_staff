module Stats
  class R007ClosedCasesReport
    class << self
      def title
        'Closed cases report'
      end

      def description
        'Entire list of closed cases'
      end

      def xlsx?
        false
      end

      def persist_results?
        true
      end

      def process(report_guid:, user:, period_start:, period_end: Date.today)
        scope =
          CaseFinderService.new(user)
            .closed_cases_scope
            .where(received_date: [period_start..period_end])
            .order(received_date: :asc)

        etl = Stats::ETL::ClosedCases.new(retrieval_scope: scope)
        report = Report.find_by(guid: report_guid)

        # Put the generated report into Redis for consumption by web app
        redis = Redis.new
        data = nil
        File.open(etl.results_filepath, 'r') { |f| data = f.read }
        redis.set(report_guid, data)

        if report
          report.report_data = {
            status: 'complete',
            filepath: etl.results_filepath,
            user_id: user.id,
            report_guid: report_guid,
            filename: etl.filename,
          }.to_json

          report.save!
        end
      end
    end

    attr_reader :period_start, :period_end, :user

    def initialize(**options)
      @reporting_period = ReportingPeriod::Calculator.build(
        period_start: options[:period_start],
        period_end: options[:period_end],
        period_name: report_type.default_reporting_period
      )

      @user = options[:user]
      @period_start = @reporting_period.period_start
      @period_end = @reporting_period.period_end
    end

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope
    end

    def report_type
      ReportType.r007
    end

    def default_reporting_period
      report_type.default_reporting_period
    end

    def persist_results?
      self.class.persist_results?
    end

    def etl?
      self.class.etl?
    end

    # Using a job allows processing to be offloaded into a separate
    # server/container instance, increasing responsiveness of the web app.
    def run(**args)
      raise ArgumentError.new('Missing report_guid') unless args[:report_guid].present?

      ::Warehouse::ClosedCasesCreateJob.perform_later(
        args[:report_guid],
        @user.id,
        @period_start.to_i,
        @period_end.to_i
      )
    end
  end
end

