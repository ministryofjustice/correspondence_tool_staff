module Stats
  class R105SarMonthlyPerformanceReport < BaseMonthlyPerformanceReport

    def self.title
      'Monthly report'
    end

    def self.description
      'Includes performance data about SAR requests we received and responded to from the beginning of the year by month.'
    end

    def case_scope
      Case::SAR.where(created_at: @period_start..@period_end)
    end

    def report_type
      ReportType.r105
    end

  end
end
