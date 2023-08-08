module Stats
  class R501OffenderSarRetentionReport < BaseRetentionReport
    def case_scope
      CaseFinderService.new(@user).closed_cases_scope.where(type: "Case::SAR::Offender")
    end

    def report_type
      ReportType.r501
    end
  end
end
