module Stats
  class BaseClosedCasesReport < BaseReport
    class << self
      def title
        raise '#title method should be defined in sub-class of BaseClosedCasesReport'
      end

      def description
        raise '#description should be defined in sub-class of BaseClosedCasesReport'
      end

      def report_format
        BaseReport::ZIP
      end

      def etl_handler
        raise '#description should be defined in sub-class of BaseClosedCasesReport'
      end

    end

    attr_reader :period_start, :period_end, :user

    def process(report_guid:)
      @period_end ||= Date.today
      scope = case_scope
          .where(received_date: [@period_start..@period_end])
          .order(received_date: :asc)

      etl_handler = self.class.etl_handler.new(retrieval_scope: scope)
      report = Report.find_by(guid: report_guid)

      # Put the generated report into Redis for consumption by web app
      redis = Redis.new
      data = nil
      File.open(etl_handler.results_filepath, 'r') { |f| data = f.read }
      redis.set(report_guid, data)

      if report
        report.report_data = {
          filepath: etl_handler.results_filepath,
          user_id: @user.id,
        }.to_json
        report.status = Stats::BaseReport::COMPLETE
        report.filename = etl_handler.filename
        report.save!
      end
    end

    def case_scope
      raise 'This method should be defined in the child class'
    end

    def report_type
      raise '#description should be defined in sub-class of BaseClosedCasesReport'
    end

    delegate :default_reporting_period, to: :report_type

    # Using a job allows processing to be offloaded into a separate
    # server/container instance, increasing responsiveness of the web app.
    def run(**args)
      raise ArgumentError.new('Missing report_guid') unless args[:report_guid].present?

      @background_job = true
      @status = Stats::BaseReport::WAITING
      @job_ids = [args[:report_guid]]
      ::Warehouse::ClosedCasesCreateJob.perform_later(
        self.class.name,
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
        redis.get(report.guid)
      end
    end

  end
end

