class CasePolicy

  attr_reader :user, :case, :failed_checks, :policy_workflow

  def initialize(user, kase)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user

    @case = kase
    @user = user

    @policy_workflow = policy_workflow_for_case(kase, user: user)
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
    @policy_workflow.respond_to?(name, include_private)
  end

  def method_missing(method, *args, &block)
    @policy_workflow.send(method, *args, &block)
  end

  def policy_workflow_for_case(kase, user:)
    workflow_class = if kase.respond_to?(:workflow) && kase.workflow.present?
                       "Cases::#{kase.category.abbreviation}::#{kase.workflow}Policy"
                     else
                       # This will have to change at some point, i.e. when we
                       # have non-FOI cases. At that time, we'll have to ensure
                       # we pass in the FOI class and use that to generate the
                       # policy below.
                       "Cases::FOIPolicy"
                     end
    workflow_class.constantize.new(user, kase)
  end
end
