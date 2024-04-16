module Stats
  class R502OffenderSARComplaintRetentionReport < BaseRetentionReport
    CSV_COLUMN_HEADINGS = [
      "Case Number (aka DPA number)",
      "Case Type",
      "Complaint Type",
      "Data Subject Name",
      "Case History Date",
      "Case History Who",
      "Case History Team",
      "Case History Action",
    ].freeze

    def initialize(**)
      @result_set = [CSV_COLUMN_HEADINGS]
      super
    end

    def report_type
      ReportType.r502
    end

    def case_scope
      Case::Base.offender_sar_complaint
        .closed
        .joins(:transitions)
        .where(case_transitions: { most_recent: true })
        .where(case_transitions: { created_at: @period_start..@period_end })
    end

    def process(kase)
      ct = kase.transitions.most_recent.decorate

      [
        kase.number,
        kase.decorate.pretty_type,
        kase.complaint_subtype.humanize,
        kase.subject_full_name,
        ct.created_at.strftime("%F"),
        ct.user_name,
        ct.user_team,
        ct.event_desc,
      ]
    end
  end
end
