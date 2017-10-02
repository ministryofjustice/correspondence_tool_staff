class CasePolicy

  attr_reader :user, :case, :failed_checks, :workflow

  def initialize(user, kase)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user

    @case = kase
    @user = user

    if @case.respond_to?(:workflow_class) && @case.workflow_class.present?
      workflow_class = @case.workflow_class
    else
      workflow_class = Workflows::Cases::FOIPolicy
    end
    @workflow = workflow_class.new(user, kase)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.manager?
        scope.all
      elsif user.responder?
        scope.with_teams(user.responding_teams)
      elsif user.approver?
        scope.all
      else
        Case.none
      end
    end
  end

  private

  def respond_to_missing?(name, include_private = false)
    @workflow.respond_to?(name, include_private)
  end

  def method_missing(method, *args, &block)
    @workflow.send(method, *args, &block)
  end
end
