module Stats
  class R003BusinessUnitPerformanceReport < BaseReport

    COLUMNS = {
      business_group:                  'Business group',
      directorate:                     'Directorate',
      business_unit:                   'Business unit',
      responsible:                     'Responsible',
      non_trigger_performance:         'Performance %',
      non_trigger_responded_in_time:   'Responded - in time',
      non_trigger_responded_late:      'Responded - late',
      non_trigger_open_in_time:        'Open - in time',
      non_trigger_open_late:           'Open - late',
      trigger_performance:             'Performance %',
      trigger_responded_in_time:       'Responded - in time',
      trigger_responded_late:          'Responded - late',
      trigger_open_in_time:            'Open - in time',
      trigger_open_late:               'Open - late',
      overall_performance:             'Performance %'
    }.freeze

    SUPERHEADINGS = {
      business_group:                  '',
      directorate:                     '',
      business_unit:                   '',
      responsible:                     '',
      non_trigger_performance:         'Non-trigger FOIs',
      non_trigger_responded_in_time:   'Non-trigger FOIs',
      non_trigger_responded_late:      'Non-trigger FOIs',
      non_trigger_open_in_time:        'Non-trigger FOIs',
      non_trigger_open_late:           'Non-trigger FOIs',
      trigger_performance:             'Trigger FOIs',
      trigger_responded_in_time:       'Trigger FOIs',
      trigger_responded_late:          'Trigger FOIs',
      trigger_open_in_time:            'Trigger FOIs',
      trigger_open_late:               'Trigger FOIs',
      overall_performance:             'Overall'
    }.freeze


    def initialize
      super
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @stats = StatsCollector.new(Team.hierarchy.map(&:id), COLUMNS)
      @superheadings = superheadings
      @stats.add_callback(:before_finalise, method(:roll_up_stats))
      @stats.add_callback(:before_finalise, method(:populate_team_details))
      @stats.add_callback(:before_finalise, method(:calculate_percentages))
    end

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        SUPERHEADINGS.values
      ]
    end

    def self.title
      'Business Unit Performance Report'
    end

    def self.description
      'Shows all open cases and cases closed this month, in-time or late, by responding team'
    end

    def run
      case_ids = (closed_case_ids + open_case_ids).uniq
      case_ids.each { |case_id| analyse_case(case_id) }
      @stats.finalise
    end

    def to_csv
      @stats.to_csv(row_names_as_first_column: false, superheadings: superheadings)
    end

    private

    # this method is passed into the stats collector as a before_finalize callback and accesses the
    # @stats variable  inside the stats collector to sum totals for directorates and business groups
    def roll_up_stats
      [ BusinessUnit, Directorate ].each do |child_klass|
          child_klass.all.each do |child_team|
            child_result_set = @stats.stats[child_team.id]
            parent_result_set = @stats.stats[child_team.parent.id]
            child_result_set.each { |key, value|  parent_result_set[key] += value }
          end
      end
    end

    # another callback method to populate the team names from the team id column
    def populate_team_details
      @stats.stats.each do | team_id, result_set|
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
    end

    # another callback method
    def calculate_percentages
      @stats.stats.each do | _team_id, row |
        row[:non_trigger_performance]  = calculate_non_trigger(row)
        row[:trigger_performance]  = calculate_trigger(row)
        row[:overall_performance]  = calculate_overall(row)
      end
    end

    def calculate_non_trigger(row)
      calculate_percentage(row[:non_trigger_responded_in_time], row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late])
    end

    def calculate_trigger(row)
      calculate_percentage(row[:trigger_responded_in_time], row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late])
    end

    def calculate_overall(row)
      value = row[:trigger_responded_in_time] + row[:non_trigger_responded_in_time]
      total = row[:non_trigger_responded_in_time] + row[:non_trigger_responded_late] + row[:non_trigger_open_late] +
              row[:trigger_responded_in_time] + row[:trigger_responded_late] + row[:trigger_open_late]
      calculate_percentage(value, total)
    end

    def calculate_percentage(value, total)
      if total == 0
        0.0
      else
        ((value / total.to_f) * 100).round(1)
      end
    end


    def closed_case_ids
      Case.closed.where(date_responded: [@period_start..@period_end]).pluck(:id)
    end

    def open_case_ids
      Case.opened.pluck(:id)
    end

    def analyse_case(case_id)
      kase = Case.find case_id
      return if kase.unassigned?
      timeliness = kase.closed? ? analyse_closed_case(kase) : analyse_open_case(kase)
      column_key = add_trigger_state(kase, timeliness)
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
