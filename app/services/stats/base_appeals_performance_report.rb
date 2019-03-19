module Stats
  class BaseAppealsPerformanceReport < BaseReport

    R002_SPECIFIC_COLUMNS = {
        business_group:                  'Business group',
        directorate:                     'Directorate',
        business_unit:                   'Business unit',
        responsible:                     'Responsible'
    }

    R002_SPECIFIC_SUPERHEADINGS = {
        business_group:                  '',
        directorate:                     '',
        business_unit:                   '',
        responsible:                     ''
    }

    class << self
      def xlsx?
        true
      end
    end

    def initialize(period_start = nil, period_end = nil)
      super
      @stats = StatsCollector.new(Team.hierarchy.map(&:id) + [:total], column_headings)
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, -> { roll_up_stats_callback })
      @stats.add_callback(:before_finalise, -> { populate_team_details_callback })
      @stats.add_callback(:before_finalise, -> { AppealCalculations::Callbacks.calculate_total_columns(@stats, appeal_types) })
      @stats.add_callback(:before_finalise, -> { AppealCalculations::Callbacks.calculate_percentages(@stats, appeal_types) })
    end

    def run
      Case::Base.find(case_ids).reject { |k| k.unassigned? }.each { |kase| analyse_case(kase) }
      @stats.finalise
    end

    def to_csv
      csv = @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)

      csv.map.with_index do |row, row_index|
        row.map.with_index do |item, item_index|
          # data rows start at index 3 as there are 2 superheadings + 1 heading
          if row_index <= superheadings.size
            OpenStruct.new value: item
            # item at index+1 is the case count - don't mark 0/0 as Red RAG rating
            # These are the positions of the items which need a RAG rating
          elsif [4, 11].include?(item_index) && row[item_index+1] != 0
            OpenStruct.new value: item, rag_rating: rag_rating(item)
          else
            OpenStruct.new value: item
          end
        end
      end
    end

    private

    # this method is passed into the stats collector as a before_finalize callback and accesses the
    # @stats variable  inside the stats collector to sum totals for directorates and business groups
    def roll_up_stats_callback
      overall_total_results = @stats.stats[:total]
      BusinessUnit.all.each do |bu|
        bu_results = @stats.stats[bu.id]
        directorate_results = @stats.stats[bu.directorate.id]
        business_group_results = @stats.stats[bu.business_group.id]
        bu_results.each do |key, value|
          directorate_results[key] += value
          business_group_results[key] += value
          overall_total_results[key] += value
        end
      end
    end

    # another callback method to populate the team names from the team id column
    def populate_team_details_callback
      stats_by_team = @stats.stats.except(:total)
      teams = Team.includes(:team_leader, parent: :parent).find(stats_by_team.keys)

      stats_by_team.each do |team_id, result_set|
        team = teams.detect { |t| t.id == team_id }
        case team.class.to_s
          when 'BusinessUnit'
            result_set[:business_unit] = team.name
            result_set[:directorate] = team.parent.name
            result_set[:business_group] = team.parent.parent.name
          when 'Directorate'
            result_set[:business_unit] = ''
            result_set[:directorate] = team.name
            result_set[:business_group] = team.parent.name
          when 'BusinessGroup'
            result_set[:business_unit] = ''
            result_set[:directorate] = ''
            result_set[:business_group] = team.name
          else
            raise "Invalid team type"
        end
        result_set[:responsible] = team.team_leader_name
      end

      @stats.stats[:total][:business_group] = 'Total'
      @stats.stats[:total][:directorate] = ''
      @stats.stats[:total][:business_unit] = ''
      @stats.stats[:total][:responsible] = ''
    end

    def analyse_case(kase)
      column_key = analyse_timeliness(kase)
      @stats.record_stats(kase.responding_team.id, column_key)
    end

    def analyse_timeliness(kase)
      AppealAnalyser.new(kase).result
    end

    def analyse_closed_case(kase)
      kase.responded_in_time? ? 'responded_in_time' : 'responded_late'
    end

    def analyse_open_case(kase)
      kase.already_late? ? 'open_late' : 'open_in_time'
    end
  end
end
