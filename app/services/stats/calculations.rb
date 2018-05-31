module Stats
  module Calculations

    module Callbacks
      def self.calculate_overall_columns(stats)
        stats.stats.each do |_team_id, row|
          Calculations::calculate_overall_figure(row, :responded_in_time)
          Calculations::calculate_overall_figure(row, :responded_late)
          Calculations::calculate_overall_figure(row, :open_in_time)
          Calculations::calculate_overall_figure(row, :open_late)
        end
      end

      def self.calculate_total_columns(stats)
        stats.stats.each do | _team_id, row |
          row[:non_trigger_total] = Calculations::sum_all_received(:non_trigger, row)
          row[:trigger_total] = Calculations::sum_all_received(:trigger, row)
          row[:overall_total] = Calculations::sum_all_received(:overall, row)
          if row.key?(:bu_total)
            row[:bu_total] = Calculations::sum_all_received(:bu, row)
          end
        end
      end

      def self.calculate_percentages(stats)
        stats.stats.each do | _team_id, row |
          row[:non_trigger_performance]  = Calculations::calculate_non_trigger(row)
          row[:trigger_performance]  = Calculations::calculate_trigger(row)
          row[:overall_performance]  = Calculations::calculate_overall_performance(row)
          if row.key?(:bu_total)
            row[:bu_performance] = Calculations::calculate_bu(row)
          end
        end
      end
    end


    def self.calculate_overall_figure(row, cat)
      target = "overall_#{cat}".to_sym
      source_1 = "non_trigger_#{cat}".to_sym
      source_2 = "trigger_#{cat}".to_sym
      row[target] = row[source_1] + row[source_2]
    end

    def self.calculate_overall_performance(row)
      value = row[:trigger_responded_in_time] + row[:non_trigger_responded_in_time]
      total = row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late] +
        row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late]
      calculate_percentage(value, total)
    end

    def self.sum_all_received(prefix, row)
      ttl = "#{prefix}_total".to_sym
      rit = "#{prefix}_responded_in_time".to_sym
      rl  = "#{prefix}_responded_late".to_sym
      oit = "#{prefix}_open_in_time".to_sym
      ol  = "#{prefix}_open_late".to_sym
      row[ttl] = row[rit] + row[rl] + row[oit] + row[ol]
    end

    def self.calculate_non_trigger(row)
      calculate_percentage(row[:non_trigger_responded_in_time], row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late])
    end

    def self.calculate_trigger(row)
      calculate_percentage(row[:trigger_responded_in_time], row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late])
    end

    def self.calculate_bu(row)
      calculate_percentage(row[:bu_responded_in_time], row[:bu_responded_in_time] + row[:bu_responded_late] + row[:bu_open_late])
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
