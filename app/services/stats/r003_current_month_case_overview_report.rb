module Stats
  class R003CurrentMonthCaseOverviewReport < BaseReport

    COLUMNS = {
      responded_in_time: 'Responded - in time',
      responded_late: 'Responded - late',
      open_in_time: 'Open - in time',
      open_late: 'Open - late'
    }

    def initialize
      super
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @stats = StatsCollector.new(Team.all.map(&:name).sort, COLUMNS.values)
    end

    def self.title
      'Current Month Case Overview Report'
    end

    def self.description
      'Shows all open cases and cases responded this month, in-time or late, by team'
    end

    def run
      case_ids = (responded_case_ids + open_case_ids).uniq
      case_ids.each { |case_id| analyse_case(case_id) }
    end

    private

    def responded_case_ids
      respond_events = CaseTransition.responded.where(created_at: [@period_start..@period_end])
      respond_events.map(&:case_id)
    end

    def open_case_ids
      Case.opened.pluck(:id)
    end

    def analyse_case(case_id)
      kase = Case.find case_id
      if kase.responded?
        status = analyse_responded_case(kase)
        team = kase.responding_team.name
      else
        status = analyse_open_case(kase)
        team = kase.current_team_and_user.team.name
      end
      @stats.record_stats(team, COLUMNS[status])
    end

    def analyse_responded_case(kase)
      kase.responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case(kase)
      kase.already_late? ? :open_late : :open_in_time
    end
  end
end
