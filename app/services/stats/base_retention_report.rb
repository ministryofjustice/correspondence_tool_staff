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

      def persist_results?
        false
      end
    end

    # rubocop:disable Lint/MissingSuper
    def initialize(**)
      @result_set = [CSV_COLUMN_HEADINGS]
    end
    # rubocop:enable Lint/MissingSuper

    def results
      @result_set
    end

    def set_results(data)
      @result_set = data
    end

    def report_type
      raise "#description should be defined in sub-class of BaseRetentionReport"
    end

    def filename
      report_type.filename(self.class.report_format)
    end

    def case_scope
      Case::SAR::Offender
        .closed
        .joins(:transitions)
        .where(case_transitions: { most_recent: true })
        .where(case_transitions: { created_at: @period_start..@period_end })
    end

    def run(*)
      case_scope.each { |kase| process(kase) }
    end

    def process(kase)
      ct = kase.transitions.most_recent.decorate

      @result_set << [
        kase.number,
        kase.decorate.pretty_type,
        kase.offender_sar_complaint? ? kase.complaint_subtype.humanize : "",
        kase.subject_full_name,
        ct.created_at.strftime("%F"),
        ct.user_name,
        ct.user_team,
        ct.event_desc,
      ]
    end

    def to_csv
      @result_set.map do |row|
        row.map { |item| OpenStruct.new(value: item) }
      end
    end
  end
end
