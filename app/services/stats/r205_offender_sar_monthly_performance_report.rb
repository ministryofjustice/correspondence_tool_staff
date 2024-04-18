module Stats
  class R205OffenderSARMonthlyPerformanceReport < BaseMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about Offender SAR requests we received and responded to from the beginning of the year by month."
      end

      def indexes_for_percentage_columns
        [1].freeze
      end

      def report_notes
        ["Performance % =  (Responded - in time / Total received) * 100 "]
      end

      def case_analyzer
        Stats::OffenderSARAnalyser
      end
    end

    def case_scope
      Case::Base.offender_sar.where(received_date: @period_start..@period_end).where.not("LEFT(cases.number, 1) = 'R'")
    end

    def report_type
      ReportType.r205
    end

    def add_report_callbacks
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_percentages(@stats) })
    end
  end
end
