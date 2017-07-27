module Stats
  class R003BusinessUnitPerformanceReport < BaseReport

    COLUMNS = {
      non_trigger_responded_in_time:  'Responded - in time',
      non_trigger_responded_late:     'Responded - late',
      non_trigger_open_in_time:       'Open - in time',
      non_trigger_open_late:          'Open - late',
      trigger_responded_in_time:      'Responded - in time',
      trigger_responded_late:         'Responded - late',
      trigger_open_in_time:           'Open - in time',
      trigger_open_late:              'Open - late'
    }

    def initialize
      super
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @stats = StatsCollector.new(BusinessUnit.responding.map(&:name).sort, COLUMNS)
      @superheadings = superheadings
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
    end

    private

    def superheadings
      [
        ["#{self.class.title} - #{reporting_period}"],
        ['', 'Non-trigger FOIs', 'Non-trigger FOIs', 'Non-trigger FOIs', 'Non-trigger FOIs', 'Trigger FOIs', 'Trigger FOIs', 'Trigger FOIs', 'Trigger FOIs', 'Trigger FOIs']
      ]
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
      team = kase.responding_team.name
      timeliness = kase.closed? ? analyse_closed_case(kase) : analyse_open_case(kase)
      column_key = add_trigger_state(kase, timeliness)
      @stats.record_stats(team, column_key)
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
