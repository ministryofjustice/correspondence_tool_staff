class CaseFinderService

  # include Pundit

  def initialize(user, action, params = {})
    @user = user
    @action = action
    @cases = []
    @params = params
  end

  def cases
    case @action
    when :index
      index_cases
    when :closed_cases
      closed_cases
    when :incoming_cases
      incoming_cases
    when :my_open_cases
      my_open_cases
    when :open_cases
      open_cases
    end
    CaseDecorator.decorate_collection(Pundit.policy_scope(@user, @cases))
  end

  private

  def index_cases
    @cases = Case.all
  end

  def closed_cases
    @cases = Case.closed.most_recent_first
  end

  def incoming_cases
    @cases = Case.flagged_for_approval(*@user.approving_teams)
               .unaccepted.by_deadline
  end

  def my_open_cases
    if @user.approver?
      @cases = Case.opened
                 .flagged_for_approval(*@user.approving_teams)
                 .with_user(@user)
                 .accepted.by_deadline
    else
      @cases = Case.opened.with_user(@user).by_deadline
    end
  end

  def open_cases
    if @user.approver?
      @cases = Case.opened.flagged_for_approval(*@user.approving_teams)
                 .accepted.by_deadline
    else
      @cases = Case.opened.by_deadline
    end
  end
end
