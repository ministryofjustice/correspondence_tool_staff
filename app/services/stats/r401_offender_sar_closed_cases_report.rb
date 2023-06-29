module Stats
  class R401OffenderSarClosedCasesReport < BaseClosedCasesReport
    class << self
      def title
        "Closed cases report"
      end

      def description
        "Entire list of closed cases"
      end

      def etl_handler
        Stats::ETL::OffenderSarClosedCases
      end
    end

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope.where(type: "Case::SAR::Offender")
    end

    def report_type
      ReportType.r401
    end
  end
end
