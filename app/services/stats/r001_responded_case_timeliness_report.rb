require 'tempfile'
require 'csv'

module Stats
  class R001RespondedCaseTimelinessReport

    def initialize
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @teams = StatsCollector.new
    end

    def run
      cases = Case.where(received_date: [@period_start..@period_end])
      cases.each { |k| analyse(k) }
    end

    def results
      @teams.stats
    end

    def to_csv
      subcats = @teams.all_subcategories
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

    def analyse(kase)
      if kase.responded?
        state = get_completion_state(kase)
        team = kase.responding_team.name
        @teams.record_stats(team, state)
      end
    end

    def get_completion_state(kase)
      kase.responded_in_time? ? 'In time' : 'Overdue'
    end
  end
end
