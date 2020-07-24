module Stats
  class R205OffenderSarMonthlyPerformanceReport < BaseMonthlyPerformanceReport
    def self.title
      'Monthly report'
    end

    def self.description
      'Includes performance data about Offender SAR requests we received and responded to from the beginning of the year by month.'
    end

    def case_scope
      Case::SAR::Offender.where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r205
    end
  end
end
