module Stats
  class BaseBusinessUnitPerformanceReport < BaseReport

    R003_SPECIFIC_COLUMNS = {
      business_group:                  'Business group',
      directorate:                     'Directorate',
      business_unit:                   'Business unit',
      responsible:                     'Responsible'
    }
    
    R003_BU_PERFORMANCE_COLUMNS = {
      bu_performance:             'Performance %',
      bu_total:                   'Total received',
      bu_responded_in_time:       'Responded - in time',
      bu_responded_late:          'Responded - late',
      bu_open_in_time:            'Open - in time',
      bu_open_late:               'Open - late',
    }

    R003_SPECIFIC_SUPERHEADINGS = {
      business_group:                  '',
      directorate:                     '',
      business_unit:                   '',
      responsible:                     ''
    }
    
    R003_BU_PERFORMANCE_SUPERHEADINGS = {
      bu_performance:             'Business unit',
      bu_total:                   'Business unit',
      bu_responded_in_time:       'Business unit',
      bu_responded_late:          'Business unit',
      bu_open_in_time:            'Business unit',
      bu_open_late:               'Business unit',
    } 
    

    def initialize(period_start = nil, period_end = nil, generate_bu_columns=false)
      super(period_start, period_end)
      # super(period_start, period_end)
      # @period_start = period_start
      # @period_end = period_end
      @generate_bu_columns = generate_bu_columns
      column_headings = if @generate_bu_columns
                          R003_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS).merge(R003_BU_PERFORMANCE_COLUMNS)
                        else
                          R003_SPECIFIC_COLUMNS.merge(CaseAnalyser::COMMON_COLUMNS)
                        end

      @stats = StatsCollector.new(Team.hierarchy.map(&:id) + [:total], column_headings)
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, -> { roll_up_stats_callback })
      @stats.add_callback(:before_finalise, -> { populate_team_details_callback })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_overall_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_total_columns(@stats) })
      @stats.add_callback(:before_finalise, -> { Calculations::Callbacks.calculate_percentages(@stats) })
    end

    def superheadings
      headings = if @generate_bu_columns
                   (R003_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS).merge(R003_BU_PERFORMANCE_SUPERHEADINGS)).values
                 else
                   (R003_SPECIFIC_SUPERHEADINGS.merge(CaseAnalyser::COMMON_SUPERHEADINGS)).values
                 end

      [
        ["#{self.class.title} - #{reporting_period}"], headings
      ]
    end

    def case_scope
      raise RuntimeError.new('#case_scope method must be defined in derived class')
    end

    def run
      CaseSelector.new(case_scope)
        .cases_for_period(@period_start, @period_end)
        .reject { |kase| kase.unassigned? }.each do |kase|
        analyse_case(kase)
      end
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
      BusinessUnit.includes(:directorate, :business_group).all.each do |bu|
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

    def analyse_case(kase)
      analyser = CaseAnalyser.new(kase)
      analyser.run
      column_key = analyser.result
      @stats.record_stats(kase.responding_team.id, column_key)

      if @generate_bu_columns
        business_unit_column_key = "bu_#{analyser.bu_result}".to_sym
        @stats.record_stats(kase.responding_team.id, business_unit_column_key)
      end
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
