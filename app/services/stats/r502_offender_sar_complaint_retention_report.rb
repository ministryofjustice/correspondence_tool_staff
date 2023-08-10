module Stats
  class R502OffenderSarComplaintRetentionReport < BaseRetentionReport
    def report_type
      ReportType.r502
    end

    def case_scope
      Case::SAR::OffenderComplaint
        .closed
        .joins(:transitions)
        .where(case_transitions: { most_recent: true })
        .where(case_transitions: { created_at: @period_start..@period_end })
    end
  end
end
