module Stats
  class R005MonthlyPerformanceReport < BaseMonthlyPerformanceReport
    # NOTES:  This name of report class is very general but actually it is only for
    # FOI standard case type, but possible not worthy taking time to rename it

    def self.title
      "Monthly report"
    end

    def self.description
      "Includes performance data about FOI requests we received and responded to from the beginning of the year by month."
    end

    def case_scope
      Case::Base.standard_foi.where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r005
    end
  end
end
