module Stats
  module SARCalculations
    module Callbacks
      def self.calculate_overall_columns(stats)
        stats.stats.each_value do |row|
          Calculations.calculate_overall_figure(row, :responded_in_time)
          Calculations.calculate_overall_figure(row, :responded_late)
          Calculations.calculate_overall_figure(row, :open_in_time)
          Calculations.calculate_overall_figure(row, :open_late)
          Calculations.calculate_overall_figure(row, :stopped)
          Calculations.calculate_overall_figure(row, :sar_extensions)
        end
      end

      def self.calculate_total_columns(stats)
        stats.stats.each_value do |row|
          row[:non_trigger_total] = sum_all_received(:non_trigger, row)
          row[:trigger_total] = sum_all_received(:trigger, row)
          row[:overall_total] = sum_all_received(:overall, row)
        end
      end

      def self.sum_all_received(prefix, row)
        ttl = "#{prefix}_total".to_sym
        ext = "#{prefix}_sar_extensions".to_sym
        rit = "#{prefix}_responded_in_time".to_sym
        rl  = "#{prefix}_responded_late".to_sym
        oit = "#{prefix}_open_in_time".to_sym
        ol  = "#{prefix}_open_late".to_sym

        row[ttl] = row[rit] + row[rl] + row[oit] + row[ol] + row[ext]
      end

      def self.calculate_percentages(stats)
        stats.stats.each_value do |row|
          Calculations.calculate_percentages_for_month(row)
        end
      end

      def self.calculate_max_achievable(stats)
        stats.stats.each_value do |row|
          row[:overall_max_achievable] = SARCalculations.calculate_max_achievable(row)
        end
      end

      def self.calculate_sar_extensions(stats)
        # TODO: Determine how to calculate SAR extensions
      end
    end

    def self.calculate_max_achievable(row)
      calculate_percentage(
        row[:non_trigger_responded_in_time] + row[:non_trigger_open_in_time],
        row[:non_trigger_total],
      )

      calculate_percentage(
        row[:trigger_responded_in_time] + row[:trigger_open_in_time],
        row[:trigger_total],
      )

      calculate_percentage(
        row[:overall_responded_in_time] + row[:overall_open_in_time],
        row[:overall_total],
      )
    end

    def self.calculate_percentage(value, total)
      if total.zero?
        0.0
      else
        ((value / total.to_f) * 100).round(1)
      end
    end
  end
end
