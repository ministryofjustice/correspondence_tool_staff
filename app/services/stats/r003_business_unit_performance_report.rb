module Stats
  class R003BusinessUnitPerformanceReport < BaseReport

    R003_SPECIFIC_COLUMNS = {
      business_group:                  'Business group',
      directorate:                     'Directorate',
      business_unit:                   'Business unit',
      responsible:                     'Responsible'
    }

    R003_SPECIFIC_SUPERHEADINGS = {
      business_group:                  '',
      directorate:                     '',
      business_unit:                   '',
      responsible:                     ''
    }

    def initialize
      super
      @period_start = Time.now.beginning_of_year
      @period_end = Time.now
      @stats = StatsCollector.new(Team.hierarchy.map(&:id) + [:total], R003_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS))
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, -> { roll_up_stats_callback })
      @stats.add_callback(:before_finalise, -> { populate_team_details_callback })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        R003_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS).values
      ]
    end

    def self.title
      'Business unit report'
    end

    def self.description
      'Shows all open cases and cases closed this month, in-time or late, by responding team'
    end

    def run
      case_ids = CaseSelector.ids_for_period(Case, @period_start, @period_end)
      case_ids.each { |case_id| analyse_case(case_id) }
      @stats.finalise
    end

    def to_csv
      @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)
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
          directorate_results   [key] += value
          business_group_results[key] += value
          overall_total_results [key] += value
        end
      end
    end

    # another callback method to populate the team names from the team id column
    def populate_team_details_callback
      @stats.stats.except(:total).each do | team_id, result_set|
        team = Team.find(team_id)
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
        result_set[:responsible] = team.team_lead
      end

      @stats.stats[:total][:business_group] = 'Total'
      @stats.stats[:total][:directorate] = ''
      @stats.stats[:total][:business_unit] = ''
      @stats.stats[:total][:responsible] = ''
    end

    def analyse_case(case_id)
      kase = Case.find case_id
      return if kase.unassigned?
      column_key = CaseAnalyser.new(kase).result
      @stats.record_stats(kase.responding_team.id, column_key)
    end

    def add_trigger_state(kase, timeliness)
      status = kase.flagged? ? 'trigger_' + timeliness : 'non_trigger_' + timeliness
      status.to_sym
    end

    def analyse_closed_case(kase)
      kase.responded_in_time? ? 'responded_in_time' : 'responded_late'
    end

    def analyse_open_case(kase)
      kase.already_late? ? 'open_late' : 'open_in_time'
    end
  end
end
