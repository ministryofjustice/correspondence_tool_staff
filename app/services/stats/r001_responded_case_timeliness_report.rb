require 'tempfile'
require 'csv'

module Stats
  class R001RespondedCaseTimelinessReport

    SUBCATEGORIES = ['In time', 'Overdue']

    def initialize
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @teams = StatsCollector.new(Team.responding.map(&:name).sort, SUBCATEGORIES)
    end

    def run
      respond_events = CaseTransition.responded.where(created_at: [@period_start..@period_end])
      respond_events.each { |re| analyse_respond_event(re) }
    end

    def results
      @teams.stats
    end

    def to_csv
      subcats = @teams.subcategories
      column_names = ['Team'] + subcats
      CSV.generate(headers: true) do |csv|
        csv << column_names
        @teams.categories.each do |cat|
          row = [cat]
          subcats.each { |subcat| row << @teams.value(cat, subcat) }
          csv << row
        end
      end
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
