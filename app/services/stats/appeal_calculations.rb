module Stats
  module AppealCalculations

    module Callbacks

      def self.calculate_total_columns(stats, appeal_types)
        appeal_types.each do |appeal_type|
          stats.stats.each do | _team_id, row |
            row_name = "#{appeal_type}_appeal_total".to_sym
            row[row_name] = AppealCalculations::sum_all_received(row, appeal_type)
          end
        end
      end

      def self.calculate_percentages(stats, appeal_types)
        appeal_types.each do |appeal_type|
          stats.stats.each do | _team_id, row |
            row_name = "#{appeal_type}_appeal_performance".to_sym
            row[row_name]  = AppealCalculations::calculate_overall_performance(row, appeal_type)
          end
        end
      end
    end

    def self.calculate_overall_performance(row, appeal_type)
      rit = "#{appeal_type}_appeal_responded_in_time".to_sym
      rl = "#{appeal_type}_appeal_responded_late".to_sym
      ol = "#{appeal_type}_appeal_open_late".to_sym

      value = row[rit]
      total = row[rit] + row[rl] + row[ol]
      calculate_percentage(value, total)
    end

    def self.sum_all_received(row, appeal_type)
      ttl = "#{appeal_type}_appeal_total".to_sym
      rit = "#{appeal_type}_appeal_responded_in_time".to_sym
      rl  = "#{appeal_type}_appeal_responded_late".to_sym
      oit = "#{appeal_type}_appeal_open_in_time".to_sym
      ol  = "#{appeal_type}_appeal_open_late".to_sym
      row[ttl] = row[rit] + row[rl] + row[oit] + row[ol]
    end

    def self.calculate_appeal(row, appeal_type)
      rit = "#{appeal_type}_appeal_responded_in_time".to_sym
      rl = "#{appeal_type}appeal_responded_late".to_sym
      ol = "#{appeal_type}appeal_open_late".to_sym
      calculate_percentage(row[rit], row[rit] + row[rl] + row[ol])
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
