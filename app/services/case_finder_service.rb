class CaseFinderService

  include Pundit

  def initialize(user, action)
    @user = user
    @action = action
    @cases = []
  end

  def cases
    case @action
    when :index
      index_cases
    when :closed_cases
      closed_cases
    when :incoming_cases
      incoming_cases
    end
    CaseDecorator.decorate_collection(@cases)
  end

  # We need to expose current user for Pundit (#lame)
  def current_user
    @user
  end

  private

  def index_cases
    @cases = policy_scope(Case.open.by_deadline)
  end

  def closed_cases
    @cases = policy_scope(Case.closed)
  end

  def incoming_cases
    team_cases = Case.waiting_to_be_accepted(*current_user.teams)
    @cases = policy_scope(team_cases)
  end


end
