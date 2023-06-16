module Stats
  class R402OffenderSarComplaintClosedCasesReport < BaseClosedCasesReport
    class << self
      def title
        "Closed complaint cases report"
      end

      def description
        "Entire list of closed complaint cases"
      end

      def etl_handler
        Stats::ETL::OffenderSarComplaintClosedCases
      end
    end

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope.where(type: "Case::SAR::OffenderComplaint")
    end

    def report_type
      ReportType.r402
    end
  end
end
