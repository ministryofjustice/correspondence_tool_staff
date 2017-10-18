class CaseFinderService
  attr_reader :user

  def initialize(user = nil, cases=nil)
    @user = user
    @cases = cases || Case.all
  end

  def cases
    @user ? Pundit.policy_scope(user, @cases) : @cases
  end

  def for_user(user)
    chain @cases, user
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def for_action(action)
    case action.to_s
    when 'index'
      index_cases
    when 'closed_cases'
      closed_cases
    when 'incoming_cases_dacu_disclosure'
      incoming_cases_dacu_disclosure
    when 'incoming_cases_press_office'
      incoming_cases_press_office
    when 'incoming_cases_private_office'
      incoming_cases_private_office
    when 'my_open_cases'
      my_open_cases
    when 'open_cases'
      open_cases
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def filter_for_params(params, url_params = {})
    result = self
    if params[:timeliness]
      result = timeliness(params[:timeliness])
    end
    if url_params['states']
      result = result.in_states(url_params['states'])
    end
    result
  end

  def index_cases
    self
  end

  def closed_cases
    chain @cases.closed.most_recent_first
  end

  def incoming_cases_dacu_disclosure
    chain @cases
      .flagged_for_approval(*@user.approving_team)
      .unaccepted.by_deadline
  end

  def incoming_cases_press_office
    new_cases_from_last_3_days([BusinessUnit.press_office])
  end

  def incoming_cases_private_office
    new_cases_from_last_3_days([BusinessUnit.private_office])
  end

  def my_open_cases
    if @user.approver?
      chain @cases.opened
        .flagged_for_approval(*@user.approving_team)
        .with_user(@user)
        .accepted.by_deadline
    else
      chain @cases.opened.with_user(@user).by_deadline
    end
  end

  def open_cases
    if @user.approver?
      chain @cases.opened
        .flagged_for_approval(*@user.approving_team)
        .accepted
        .by_deadline
    else
      chain @cases.opened.by_deadline
    end
  end

  def timeliness(timeliness)
    case timeliness
    when 'in_time' then chain @cases.in_time
    when 'late'    then chain @cases.late
    end
  end

  def in_states(states)
    chain @cases.in_states(states.split(','))
  end

  private

  def chain(cases, user = @user)
    self.class.new(user, cases)
  end

  def new_cases_from_last_3_days(team)
    chain @cases
      .where(created_at: (3.business_day.ago.beginning_of_day..
          1.business_days.ago.end_of_day))
              .not_with_teams(team)
              .order(id: :desc)
  end
end
