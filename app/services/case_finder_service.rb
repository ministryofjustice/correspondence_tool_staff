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
    when :my_open_cases
      my_open_cases
    when :open_cases
      open_cases
    end
    CaseDecorator.decorate_collection(policy_scope(@cases))
  end

  # We need to expose current user for Pundit (#lame)
  def current_user
    @user
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
      @cases = Case.open
                 .flagged_for_approval(*@user.approving_teams)
                 .with_user(@user)
                 .accepted.by_deadline
    else
      @cases = Case.open.with_user(@user).by_deadline
    end
  end

  def open_cases
    if @user.approver?
      @cases = Case.open.flagged_for_approval(*@user.approving_teams)
                 .accepted.by_deadline
    else
      @cases = Case.open.by_deadline
    end
  end
end
