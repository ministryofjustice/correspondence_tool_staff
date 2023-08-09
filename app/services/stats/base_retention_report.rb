module Stats
  class BaseRetentionReport < BaseReport
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

    class << self
      def title
        "Retention report"
      end

      def description
        "Shows cases whose last action was between the selected dates"
      end

      def report_format
        BaseReport::XLSX
      end
    end

    def results
      @result_set
    end

    def set_results(data)
      @result_set = data
    end

    def report_type
      raise "#description should be defined in sub-class of BaseRetentionReport"
    end

    def case_scope
      Case::SAR::Offender
        .closed
        .joins(:transitions)
        .where(case_transitions: { most_recent: true })
        .where(case_transitions: { created_at: @period_start..@period_end })
    end

    def run(*)
      @background_job = false
      @status = Stats::BaseReport::COMPLETE
    end

    def analyse_case(kase)
      ct = kase.transitions.most_recent.decorate

      [
        kase.number,
        kase.decorate.pretty_type,
        kase.offender_sar_complaint? ? kase.complaint_subtype.humanize : "",
        kase.subject_full_name,
        ct.action_date,
        ct.user_name,
        ct.user_team,
        ct.event_desc,
      ]
    end

    def to_csv
      case_scope.map do |kase|
        analyse_case(kase).map do |item|
          OpenStruct.new value: item
        end
      end
    end
  end
end
