module Stats
  class R005MonthlyPerformanceReport < BaseMonthlyPerformanceReport

    def self.title
      'Monthly report'
    end

    def self.description
      'Includes performance data about FOI requests we received and responded to from the beginning of the year by month.'
    end

    def case_scope
      Case::Base.standard_foi.where(created_at: @period_start..@period_end)
    end

    def report_type
      ReportType.r005
    end

  end
end
