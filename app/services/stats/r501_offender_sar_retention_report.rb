module Stats
  class R501OffenderSarRetentionReport < BaseRetentionReport
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
