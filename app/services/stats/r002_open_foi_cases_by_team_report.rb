require 'tempfile'

module Stats
  class R002OpenFoiCasesByTeamReport

    COLUMNS = ['No. of cases']
    COLNAME = COLUMNS.first

    def initialize
      @teams = StatsCollector.new(Team.all.map(&:name).sort, COLUMNS)
    end

    def self.title
      'Open FOI Cases by Team Report'
    end

    def self.description
      'Count of all FOI cases which have not been marked as response sent, by team'
    end

    def run
      foi = Category.where(abbreviation: 'FOI').first
      cases = foi.cases.opened
      cases.each { |kase| analyse_case(kase) }
    end

    def to_csv
      @teams.to_csv('Team')
    end


    private

    def analyse_case(kase)
      if kase.transitions.responded.empty?
        team = kase.current_team_and_user.team
        @teams.record_stats(team.name, COLNAME) unless team.nil?
      end

    end

    def get_completion_state(kase)
      kase.responded_in_time? ? 'In time' : 'Overdue'
    end
  end
end
