module Stats
  class R208OffenderLitigationComplaintMonthlyPerformanceReport < R205OffenderSarMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about litigation Offender complaint requests we received and responded to from the beginning of the year by month."
      end
    end

    def case_scope
      Case::Base.offender_sar_complaint
      .where("properties->>'complaint_type'::text = ? ", "litigation_complaint")
      .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r208
    end
  end
end
