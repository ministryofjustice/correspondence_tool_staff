module Stats
  class R205OffenderSARMonthlyPerformanceReport < BaseMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about Offender SAR requests we received and responded to from the beginning of the year by month excluding missing DPS cases."
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
      Case::Base.offender_sar.where(received_date: @period_start..@period_end).where.not("LEFT(cases.number, 1) = 'R' OR LEFT(cases.number, 1) = 'D'")
    end

    def report_type
      ReportType.r205
    end

    def add_report_callbacks
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_percentages(@stats) })
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_max_achievable(@stats) })
      @stats.add_callback(:before_finalise, -> { OffenderSARCalculations::Callbacks.calculate_sar_extensions(@stats) })
    end

    def analyse_case(kase)
      super do |month, column_key|
        @stats.record_stats(month, column_key)

        unless kase.stopped?
          @stats.record_stats(:total, column_key)
        end

        # TODO: Implement extend_sar_deadline event for Offender SARs
        if kase.try(:sar_extensions)&.any?
          @stats.record_stats(month, :overall_sar_extensions)
        end

        if kase.stopped?
          @stats.record_stats(month, :overall_stopped)
        end
      end
    end
  end
end
