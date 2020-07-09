module Stats
  class R007ClosedCasesReport < BaseReport
    class << self
      def title
        'Closed cases report'
      end

      def description
        'Entire list of closed cases'
      end

      def report_format
        BaseReport::ZIP
      end

      def process(report_guid:, user:, period_start:, period_end: Date.today)
        scope =
          CaseFinderService.new(user)
            .closed_cases_scope
            .where(received_date: [period_start..period_end])
            .order(received_date: :asc)

        etl_handler = Stats::ETL::ClosedCases.new(retrieval_scope: scope)
        report = Report.find_by(guid: report_guid)

        # Put the generated report into Redis for consumption by web app
        redis = Redis.new
        data = nil
        File.open(etl_handler.results_filepath, 'r') { |f| data = f.read }
        redis.set(report_guid, data)

        if report
          report.report_data = {
            filepath: etl_handler.results_filepath,
            user_id: user.id,
          }.to_json
          report.status = Stats::BaseReport::COMPLETE
          report.filename = etl_handler.filename
          report.save!
        end
      end
    end

    attr_reader :period_start, :period_end, :user

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope
    end

    def report_type
      ReportType.r007
    end

    def default_reporting_period
      report_type.default_reporting_period
    end

    # Using a job allows processing to be offloaded into a separate
    # server/container instance, increasing responsiveness of the web app.
    def run(**args)
      raise ArgumentError.new('Missing report_guid') unless args[:report_guid].present?

      @etl = true
      @status = Stats::BaseReport::WAITING
      @job_ids = [args[:report_guid]]
      ::Warehouse::ClosedCasesCreateJob.perform_later(
        args[:report_guid],
        @user.id,
        @period_start.to_i,
        @period_end.to_i
      )
    end

    def report_details(report)
      redis = Redis.new
      if redis.exists(report.guid)
        report.status = Stats::BaseReport::COMPLETE
        report.save!
        Redis.new.get(report.guid)
      end
    end
  
  end
end

