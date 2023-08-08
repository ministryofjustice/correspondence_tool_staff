module Stats
  class R502OffenderSarComplaintRetentionReport < BaseRetentionReport
    def case_scope
      CaseFinderService.new(@user).closed_cases_scope.where(type: "Case::SAR::Offender")
    end

    def report_type
      ReportType.r502
    end
  end
end
