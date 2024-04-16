module Stats
  class R206OffenderStandardComplaintMonthlyPerformanceReport < R205OffenderSARMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about standard Offender complaint requests we received and responded to from the beginning of the year by month."
      end
    end

    def case_scope
      Case::Base.offender_sar_complaint
        .where("properties->>'complaint_type'::text = ? ", "standard_complaint")
        .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r206
    end
  end
end
