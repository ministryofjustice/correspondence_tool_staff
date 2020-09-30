module Stats
  module OffenderSarCalculations

    module Callbacks

      def self.calculate_percentages(stats)
        stats.stats.each do | _, row |
          row[:overall_performance]  = OffenderSarCalculations::calculate_overall_performance(row)
        end
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
      if total == 0
        0.0
      else
        ((value / total.to_f) * 100).round(1)
      end
    end

  end
end
