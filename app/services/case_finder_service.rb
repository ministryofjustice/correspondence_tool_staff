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
    when 'my_open_cases'
      my_open_cases
    when 'open_cases'
      open_cases
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def filter_for_params(params)
    if params[:timeliness]
      timeliness(params[:timeliness])
    end
  end

  def index_cases
    self
  end

  def closed_cases
    chain @cases.closed.most_recent_first
  end

  def incoming_cases_dacu_disclosure
    chain @cases
      .flagged_for_approval(*@user.approving_teams)
      .unaccepted.by_deadline
  end

  def incoming_cases_press_office
    chain @cases
      .where(created_at: (3.business_day.ago.beginning_of_day..
                          1.business_days.ago.end_of_day))
      .not_with_teams([Team.press_office])
      .order(id: :desc)

  end

  def my_open_cases
    if @user.approver?
      chain @cases.opened
        .flagged_for_approval(*@user.approving_teams)
        .with_user(@user)
        .accepted.by_deadline
    else
      chain @cases.opened.with_user(@user).by_deadline
    end
  end

  def open_cases
    if @user.approver?
      chain @cases.opened
        .flagged_for_approval(*@user.approving_teams)
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

  private

  def chain(cases, user = @user)
    self.class.new(user, cases)
  end
end
