module Stats
  class R207OffenderIcoComplaintMonthlyPerformanceReport < R205OffenderSarMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about ICO Offender complaint requests we received and responded to from the beginning of the year by month."
      end
    end

    def case_scope
      Case::Base.offender_sar_complaint
      .where("properties->>'complaint_type'::text = ? ", "ico_complaint")
      .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r207
    end
  end
end
