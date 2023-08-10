module Stats
  class R501OffenderSarRetentionReport < BaseRetentionReport
    def report_type
      ReportType.r501
    end

    def case_scope
      Case::SAR::Offender
        .closed
        .joins(:transitions)
        .where(case_transitions: { most_recent: true })
        .where(case_transitions: { created_at: @period_start..@period_end })
    end
  end
end
