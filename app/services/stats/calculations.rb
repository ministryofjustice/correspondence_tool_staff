module Stats
  module Calculations
    module Callbacks
      def self.calculate_overall_columns(stats)
        stats.stats.each do |_team_id, row|
          Calculations.calculate_overall_figure(row, :responded_in_time)
          Calculations.calculate_overall_figure(row, :responded_late)
          Calculations.calculate_overall_figure(row, :open_in_time)
          Calculations.calculate_overall_figure(row, :open_late)
        end
      end

      def self.calculate_total_columns(stats)
        stats.stats.each do |_team_id, row|
          row[:non_trigger_total] = Calculations.sum_all_received(:non_trigger, row)
          row[:trigger_total] = Calculations.sum_all_received(:trigger, row)
          row[:overall_total] = Calculations.sum_all_received(:overall, row)
          if row.key?(:bu_total)
            row[:bu_total] = Calculations.sum_all_received(:bu, row)
          end
        end
      end

      def self.calculate_percentages(stats)
        stats.stats.each do |_team_id, row|
          if row.key?(:business_group)
            Calculations.calculate_percentages_for_bu(row)
          else
            Calculations.calculate_percentages_for_month(row)
          end
          if row.key?(:bu_total)
            row[:bu_performance] = Calculations.calculate_bu(row)
          end
        end
      end
    end

    def self.calculate_percentages_for_month(row)
      row[:non_trigger_performance] = calculate_non_trigger(row)
      row[:trigger_performance]  = calculate_trigger(row)
      row[:overall_performance]  = calculate_overall_performance(row)
    end

    def self.calculate_percentages_for_bu(row)
      row[:non_trigger_performance] = calculate_bu_non_trigger(row)
      row[:trigger_performance]  = calculate_bu_trigger(row)
      row[:overall_performance]  = calculate_bu_overall_performance(row)
    end

    def self.calculate_overall_figure(row, cat)
      target = "overall_#{cat}".to_sym
      source_1 = "non_trigger_#{cat}".to_sym
      source_2 = "trigger_#{cat}".to_sym
      row[target] = row[source_1] + row[source_2]
    end

    def self.calculate_overall_performance(row)
      value = row[:trigger_responded_in_time] +
        row[:trigger_open_in_time] +
        row[:non_trigger_responded_in_time] +
        row[:non_trigger_open_in_time]
      total = row[:non_trigger_responded_in_time] +
        row[:non_trigger_responded_late] +
        row[:non_trigger_open_late] +
        row[:non_trigger_open_in_time] +
        row[:trigger_responded_in_time] +
        row[:trigger_responded_late] +
        row[:trigger_open_late] +
        row[:trigger_open_in_time]
      calculate_percentage(value, total)
    end

    def self.calculate_bu_overall_performance(row)
      value = row[:trigger_responded_in_time] +
        row[:trigger_open_in_time] +
        row[:non_trigger_responded_in_time] +
        row[:non_trigger_open_in_time]
      total = row[:non_trigger_responded_in_time] +
        row[:non_trigger_responded_late] +
        row[:non_trigger_open_late] +
        row[:non_trigger_open_in_time] +
        row[:trigger_responded_in_time] +
        row[:trigger_responded_late] +
        row[:trigger_open_late] +
        row[:trigger_open_in_time]
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
      calculate_percentage(
        row[:non_trigger_responded_in_time] + row[:non_trigger_open_in_time],
        row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late] + row[:non_trigger_open_in_time],
      )
    end

    def self.calculate_trigger(row)
      calculate_percentage(
        row[:trigger_responded_in_time] + row[:trigger_open_in_time],
        row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late] + row[:trigger_open_in_time],
      )
    end

    def self.calculate_bu_non_trigger(row)
      calculate_percentage(
        row[:non_trigger_responded_in_time] + row[:non_trigger_open_in_time],
        row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late] + row[:non_trigger_open_in_time],
      )
    end

    def self.calculate_bu_trigger(row)
      calculate_percentage(
        row[:trigger_responded_in_time] + row[:trigger_open_in_time],
        row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late] + row[:trigger_open_in_time],
      )
    end

    def self.calculate_bu(row)
      calculate_percentage(
        row[:bu_responded_in_time] + row[:bu_open_in_time],
        row[:bu_responded_in_time] + row[:bu_responded_late] + row[:bu_open_late] + row[:bu_open_in_time],
      )
    end

    def self.calculate_percentage(value, total)
      if total.zero?
        nil
      else
        ((value / total.to_f) * 100).round(1)
      end
    end

    # this method is passed into the stats collector as a before_finalize callback and accesses the
    # @stats variable  inside the stats collector to sum totals for directorates and business groups
    def self.roll_up_stats_callback(stats)
      overall_total_results = stats.stats[:total]
      BusinessUnit.includes(:directorate, :business_group).all.each do |bu|
        bu_results = stats.stats[bu.id]
        directorate_results = stats.stats[bu.directorate.id]
        business_group_results = stats.stats[bu.business_group.id]
        bu_results.each do |key, value|
          directorate_results[key] += value
          business_group_results[key] += value
          overall_total_results[key] += value
        end
      end
    end

    def self.populate_team_details_callback(stats)
      # This is a hash (indexed by team id) containing a hash of team stats columns
      # so removing the 'total' entry leaves just the team IDs
      stats_by_team = stats.stats.except(:total)

      teams = Team.includes(:team_leader, parent: :parent).find(stats_by_team.keys)
      stats_by_team.each do |team_id, result_set|
        team = teams.detect { |t| t.id == team_id }
        case team.class.to_s
        when "BusinessUnit"
          business_unit_result_setter(result_set, team)
        when "Directorate"
          directorate_result_setter(result_set, team)
        when "BusinessGroup"
          business_group_result_setter(result_set, team)
        else
          raise "Invalid team type #{team.class}"
        end
        default_results_setter(result_set, team)
      end
      stats_total_setter(stats)
    end

    def self.business_unit_result_setter(result_set, team)
      result_set[:business_unit] = team.name
      result_set[:business_unit_id] = team.id
      result_set[:new_business_unit_id] = team.moved_to_unit_id
      result_set[:directorate] = team.parent.name
      result_set[:business_group] = team.parent.parent.name
    end

    def self.directorate_result_setter(result_set, team)
      result_set[:business_unit] = ""
      result_set[:business_unit_id] = nil
      result_set[:new_business_unit_id] = nil
      result_set[:directorate] = team.name
      result_set[:business_group] = team.parent.name
    end

    def self.business_group_result_setter(result_set, team)
      result_set[:business_unit] = ""
      result_set[:business_unit_id] = nil
      result_set[:new_business_unit_id] = nil
      result_set[:directorate] = ""
      result_set[:business_group] = team.name
    end

    def self.default_results_setter(result_set, team)
      result_set[:deactivated] = team.deactivated
      result_set[:responsible] = team.team_leader_name
      result_set[:moved] = team.moved
    end

    def self.stats_total_setter(stats)
      stats.stats[:total][:business_group] = "Total"
      stats.stats[:total][:directorate] = ""
      stats.stats[:total][:business_unit] = ""
      stats.stats[:total][:business_unit_id] = nil
      stats.stats[:total][:new_business_unit_id] = nil
      stats.stats[:total][:responsible] = ""
      stats.stats[:total][:deactivated] = ""
      stats.stats[:total][:moved] = ""
    end
  end
end
