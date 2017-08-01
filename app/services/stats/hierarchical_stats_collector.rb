require 'csv'

module Stats

  class HierarchicalStatsCollector < StatsCollector

    def initialize(rows, stats_columns, hierarchy)
      @hierarchy = hierarchy
      super(rows, stats_columns)
    end

    def stats
      results = Hash[@stats.map { |group, stats| [group, {stats: stats}] }]
      group_child_stats_by_parent_recursively(results, @hierarchy.keys[0..-2])
    end

    def to_csv(hierarchy_columns, superheadings = [Array.new])
      cols = hierarchy_columns.map { |h| @hierarchy[h] } + column_names
      CSV.generate(headers: true) do |csv|
        superheadings.each { |superheading| csv << superheading }
        csv << cols

        csv_stats_recursively(csv)
      end
    end

    private

    def group_child_stats_by_parent_recursively(child_stats, parents)
      if parents.empty?
        return child_stats
      else
        parent_stats = {}
        parent_type = parents.pop
        child_stats.group_by do |child, _stats|
          child.__send__ parent_type
        end.each do |parent, child_group|
          parent_stats[parent] = {}
          parent_stats[parent][:children] = Hash[child_group]
          parent_stats[parent][:stats] = child_group.reduce({}) do |new_stats, child|
            add_child_stats_to_parent(new_stats, child.second[:stats])
          end
        end
        group_child_stats_by_parent_recursively(parent_stats, parents)
      end
    end

    def csv_stats_recursively(csv, stats_groups = nil, parent_groups = [])
      return csv if parent_groups.count >= @hierarchy.keys.count
      stats_groups ||= stats
      stats_groups.each do |group, group_info|
        row = parent_groups.dup
        row << group.name
        extra_row_spacing = @hierarchy.keys.count - parent_groups.count - 1
        extra_row_spacing.times { row << '' }
        @column_hash.keys.each { |col_key| row << group_info[:stats][col_key] }
        csv << row
        csv_stats_recursively(csv,
                              group_info[:children],
                              parent_groups + [group.name])
      end
    end

    def add_child_stats_to_parent(parent_stats, child_stats)
      Hash[
        @column_hash.keys.map do |column|
          new_value = parent_stats.fetch(column, 0) + child_stats[column]
          [column, new_value]
        end
      ]
    end
  end
end
