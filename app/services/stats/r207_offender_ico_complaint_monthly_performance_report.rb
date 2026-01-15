module Stats
  class R207OffenderICOComplaintMonthlyPerformanceReport < R205OffenderSARMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about ICO Offender complaint requests we received and responded to from the beginning of the year by month excluding missing DPS cases."
      end
    end

    # NOTE: Historical Complaint cases prior to 2025-08-14 will not contain
    # the `proeprties->>flag_as_dps_missing_data` attribute. Order of WHERE precedence matters
    def case_scope
      Case::Base.offender_sar_complaint
      .where("properties->>'complaint_type'::text = ? ", "ico_complaint")
      .where("properties->>'flag_as_dps_missing_data' IS NULL OR (properties->'flag_as_dps_missing_data')::boolean = ?", false)
      .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r207
    end
  end
end
