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
    end


    attr_reader :period_start, :period_end, :user
    attr_reader :filepath

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

    def run
      scope =
        case_scope
          .where(received_date: [@period_start..@period_end])
          .order(received_date: :asc)

      options = {
        etl: ETL::ClosedCases,
        scope: scope
      }
      puts "\nPERFORMING NOW..."
      WarehouseCasesReportCreateJob.perform_now(@user.id, @period_start.to_i, @period_end.to_i)

      # etl = ETL::ClosedCases.new(retrieval_scope: scope)
      # @filepath = etl.results_filepath
    end

    def persist_results?
      self.class.persist_results?
    end
  end
end

