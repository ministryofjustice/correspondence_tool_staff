module Stats
  class R005MonthlyPerformanceReport < BaseMonthlyPerformanceReport

    def self.title
      'Monthly report (FOI)'
    end

    def self.description
      'Shows number of FOI cases in each state by month'
    end

    def case_scope
      Case::Base.standard_foi.where(created_at: @period_start..@period_end)
    end

    def report_type
      ReportType.r005
    end

  end
end
