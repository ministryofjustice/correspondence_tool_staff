require 'tempfile'

module Stats
  class R001RespondedCaseTimelinessReport

    COLUMNS = ['In time', 'Overdue']

    def initialize
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @teams = StatsCollector.new(Team.responding.map(&:name).sort, COLUMNS)
    end

    def self.title
      'Responded Cases Timeliness Report'
    end

    def self.description
      'Count of all cases where the responder has marked the reponse has sent this month, in time or overdue, by team'
    end

    def run
      respond_events = CaseTransition.responded.where(created_at: [@period_start..@period_end])
      respond_events.each { |re| analyse_respond_event(re) }
    end

    def results
      @teams.stats
    end

    def to_csv
      @teams.to_csv('Team')
    end


    private

    def analyse_respond_event(event)
      kase = event.case
      state = get_completion_state(kase)
      team = kase.responding_team.name
      @teams.record_stats(team, state)
    end

    def get_completion_state(kase)
      kase.responded_in_time? ? 'In time' : 'Overdue'
    end
  end
end
