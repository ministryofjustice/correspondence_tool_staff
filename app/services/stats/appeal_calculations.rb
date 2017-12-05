module Stats
  module AppealCalculations

    module Callbacks

      def self.calculate_total_columns(stats)
        stats.stats.each do | _team_id, row |
          row[:appeal_total] = AppealCalculations::sum_all_received(row)
        end
      end

      def self.calculate_percentages(stats)
        stats.stats.each do | _team_id, row |
          row[:appeal_performance]  = AppealCalculations::calculate_overall_performance(row)
        end
      end
    end

    def self.calculate_overall_performance(row)
      value = row[:appeal_responded_in_time]
      total = row[:appeal_responded_in_time] + row[:appeal_responded_late] + row[:appeal_open_late]
      calculate_percentage(value, total)
    end

    def self.sum_all_received(row)
      ttl = "appeal_total".to_sym
      rit = "appeal_responded_in_time".to_sym
      rl  = "appeal_responded_late".to_sym
      oit = "appeal_open_in_time".to_sym
      ol  = "appeal_open_late".to_sym
      row[ttl] = row[rit] + row[rl] + row[oit] + row[ol]
    end

    def self.calculate_appeal(row)
      calculate_percentage(row[:appeal_responded_in_time], row[:appeal_responded_in_time] + row[:appeal_responded_late] + row[:appeal_open_late])
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
