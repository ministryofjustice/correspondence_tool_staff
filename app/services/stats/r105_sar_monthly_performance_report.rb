module Stats
  class R105SarMonthlyPerformanceReport < BaseMonthlyPerformanceReport
    def self.title
      "Monthly report"
    end

    def self.description
      "Includes performance data about SAR requests we received and responded to from the beginning of the year by month."
    end

    def case_scope
      sar_tmm = CaseClosure::RefusalReason.sar_tmm
      Case::SAR::Standard
        .where("refusal_reason_id IS NULL OR refusal_reason_id != ?", sar_tmm.id)
        .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r105
    end
  end
end
