module Stats
  class R105SARMonthlyPerformanceReport < BaseMonthlyPerformanceReport
    class << self
      def title
        "Monthly report"
      end

      def description
        "Includes performance data about SAR requests we received and responded to from the beginning of the year by month."
      end

      def indexes_for_percentage_columns
        [1, 2, 10, 11, 19, 20].freeze
      end

      def case_analyzer
        Stats::StandardSARAnalyser
      end
    end

    def case_scope
      sar_tmm = CaseClosure::RefusalReason.sar_tmm
      Case::SAR::Standard
        .where("refusal_reason_id IS NULL OR refusal_reason_id != ?", sar_tmm.id)
        .where(received_date: @period_start..@period_end)
    end

    def report_type
      ReportType.r105
    end

    def add_report_callbacks
      @stats.add_callback(:before_finalise, -> { SARCalculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { SARCalculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { SARCalculations::Callbacks.calculate_percentages(@stats) })
      @stats.add_callback(:before_finalise, -> { SARCalculations::Callbacks.calculate_max_achievable(@stats) })
      @stats.add_callback(:before_finalise, -> { SARCalculations::Callbacks.calculate_sar_extensions(@stats) })
    end

    def analyse_case(kase)
      super do |month, column_key|
        @stats.record_stats(month, column_key)

        unless kase.stopped?
          @stats.record_stats(:total, column_key)
        end

        if kase.sar_extensions.any?
          @stats.record_stats(month, "#{kase.trigger_status}_sar_extensions".to_sym)
        end

        if kase.stopped?
          @stats.record_stats(month, "#{kase.trigger_status}_stopped".to_sym)
        end
      end
    end
  end
end
