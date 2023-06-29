class CaseTeamCollection
  attr_reader :teams

  def initialize(kase)
    @kase = kase
    @teams = gather_teams
  end

private

  def gather_teams
    teams = @kase.transitions.map(&:target_team) + @kase.transitions.map(&:acting_team)
    teams.compact.uniq.sort { |a, b| a.name <=> b.name }
  end
end
