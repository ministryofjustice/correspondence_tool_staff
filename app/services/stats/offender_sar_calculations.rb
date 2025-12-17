module Stats
  module OffenderSARCalculations
    module Callbacks
      def self.calculate_total_columns(stats)
        stats.stats.each_value do |row|
          row[:overall_total] = OffenderSARCalculations.sum_all_received(:overall, row)
        end
      end

      def self.calculate_percentages(stats)
        stats.stats.each_value do |row|
          row[:overall_performance] = OffenderSARCalculations.calculate_overall_performance(row)
        end
      end

      def self.calculate_max_achievable(stats)
        stats.stats.each_value do |row|
          row[:overall_max_achievable] = OffenderSARCalculations.calculate_max_achievable(row)
        end
      end

      def self.calculate_sar_extensions(stats)
        # TODO: Determine how to calculate SAR extensions
      end
    end

    def self.sum_all_received(prefix, row)
      ttl = "#{prefix}_total".to_sym
      st  = "#{prefix}_stopped".to_sym
      rit = "#{prefix}_responded_in_time".to_sym
      rl  = "#{prefix}_responded_late".to_sym
      oit = "#{prefix}_open_in_time".to_sym
      ol  = "#{prefix}_open_late".to_sym

      row[ttl] = row[rit] + row[rl] + row[oit] + row[ol] - row[st]
    end

    def self.calculate_overall_performance(row)
      value = row[:overall_responded_in_time]
      total = row[:overall_responded_in_time] +
        row[:overall_responded_late] +
        row[:overall_open_in_time] +
        row[:overall_open_late]
      calculate_percentage(value, total)
    end

    def self.calculate_max_achievable(row)
      value = row[:overall_responded_in_time] + row[:overall_open_in_time]

      calculate_percentage(value, row[:overall_total])
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
