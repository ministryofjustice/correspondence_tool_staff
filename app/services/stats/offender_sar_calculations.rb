module Stats
  module OffenderSARCalculations
    module Callbacks
      def self.calculate_total_columns(stats)
        stats.stats.each_value do |row|
          row[:overall_total] = Calculations.sum_all_received(:overall, row)
        end
      end

      def self.calculate_percentages(stats)
        stats.stats.each_value do |row|
          row[:overall_performance] = OffenderSARCalculations.calculate_overall_performance(row)
        end
      end

      def self.calculate_num_sar_extensions(stats)
        # TODO: Determine how to calculate SAR extensions
      end
    end

    def self.calculate_overall_performance(row)
      value = row[:overall_responded_in_time]
      total = row[:overall_responded_in_time] +
        row[:overall_responded_late] +
        row[:overall_open_in_time] +
        row[:overall_open_late]
      calculate_percentage(value, total)
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
