module Stats
  class R206OffenderStandardComplaintMonthlyPerformanceReport < R205OffenderSARMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about standard Offender complaint requests we received and responded to from the beginning of the year by month excluding missing DPS cases."
      end
    end

    def case_scope
      Case::Base.offender_sar_complaint
        .where("properties->>'complaint_type'::text = ? ", "standard_complaint")
        .where("properties->>'flag_as_dps_missing_data'::text = ? OR properties->>'flag_as_dps_missing_data' IS NULL", "false")
        .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r206
    end
  end
end
