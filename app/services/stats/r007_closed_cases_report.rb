module Stats
  class R007ClosedCasesReport < BaseClosedCasesReport
    class << self
      def title
        "Closed cases report"
      end

      def description
        "Entire list of closed cases"
      end

      def etl_handler
        Stats::ETL::ClosedCases
      end
    end

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope
    end

    def report_type
      ReportType.r007
    end
  end
end
