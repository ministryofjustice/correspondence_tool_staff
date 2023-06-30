class CurrentTeamAndUserService
  def initialize(kase)
    @case = kase
    @resolver = resolver_for_case(kase)
    if can_handle_the_state
      @resolver.__send__ kase.current_state
    else
      raise "State #{kase.current_state} unrecognised by #{@resolver.class}"
    end
  end

  def team
    @resolver.team
  end

  def user
    @resolver.user
  end

private

  def can_handle_the_state
    (@resolver.respond_to? @case.current_state) || (@case.class.permitted_states.include? @case.current_state)
  end

  def resolver_for_case(kase)
    kase.current_team_and_user_resolver
  end
end
