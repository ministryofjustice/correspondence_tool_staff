class CaseFinderService
  attr_reader :user, :cases

  def initialize(user, filters, params)
    @user = user
    @filters = filters
    @params = params
    @cases = apply_filters(filters, Pundit.policy_scope(user, Case))
    @cases = filter_for_params(params, @cases)
  end

  def apply_filters(filters, cases)
    filters.reduce(cases) do |filtered_cases, filter|
      filter_method = "#{filter}_filter"
      if respond_to? filter_method
        __send__(filter_method, filtered_cases)
      else
        raise NameError.new("could not find filter named #{filter_method}")
      end
    end
  end

  def index_cases_filter(cases)
    cases
  end

  def closed_cases_filter(cases)
    cases.closed.most_recent_first
  end

  def incoming_cases_dacu_disclosure_filter(cases)
    cases
      .flagged_for_approval(*@user.approving_team)
      .unaccepted.by_deadline
  end

  def incoming_cases_press_office_filter(cases)
    new_cases_from_last_3_days(cases, [BusinessUnit.press_office])
  end

  def incoming_cases_private_office_filter(cases)
    new_cases_from_last_3_days(cases, [BusinessUnit.private_office])
  end

  def my_open_cases_filter(cases)
    if @user.approver?
      cases.opened
        .flagged_for_approval(*@user.approving_team)
        .with_user(@user)
        .accepted.by_deadline
    else
      cases.opened.with_user(@user).by_deadline
    end
  end

  def open_cases_filter(cases)
    if @user.approver?
      cases.opened
        .flagged_for_approval(*@user.approving_team)
        .accepted
        .by_deadline
    else
      cases.opened.by_deadline
    end
  end

  def in_time_filter(cases)
    cases.in_time
  end

  def late_filter(cases)
    cases.late
  end

  def filter_for_params(params, cases)
    if params['states'].present?
      in_states(params['states'], cases)
    else
      cases
    end
  end

  def in_states(states, cases)
    cases.in_states(states.split(','))
  end

  private

  def new_cases_from_last_3_days(cases, team)
    cases
      .where("(properties ->> 'escalation_deadline')::date >= ?", Date.today)
      .not_with_teams(team)
      .order(id: :desc)
  end
end
