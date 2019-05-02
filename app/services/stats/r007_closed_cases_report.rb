module Stats
  class R007ClosedCasesReport < BaseCasesReport
    def self.title
      'Closed cases report'
    end

    def self.description
      'Entire list of closed cases'
    end

    def case_scope
      CaseFinderService.new(@user).closed_cases_scope
    end

    def report_type
      ReportType.r007
    end
  end
end

