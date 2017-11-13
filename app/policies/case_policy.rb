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
      scopes = []
      if user.manager?
        scopes << ->(inner_scope) { inner_scope.all }
      end

      if user.responder?
        case_ids = Assignment.with_teams(user.responding_teams).pluck(:case_id)
        scopes << -> (inner_scope) { inner_scope.where(id: case_ids) }
      end
      if user.approver?
        scopes << ->(inner_scope) { inner_scope.all }
      end

      if scopes.present?
        final_scope = scopes.shift.call(scope)
        scopes.each do |scope_func|
          final_scope.or(scope_func.call(scope))
        end
        final_scope
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
    workflow_class = kase.format_workflow_class_name(
      # This will have to change at some point, i.e. when we
      # have non-FOI cases. At that time, we'll have to ensure
      # we pass in the FOI class and use that to generate the
      # policy below.
      'Cases::%{type}Policy',
      'Cases::%{type}::%{workflow}Policy'
    )
    workflow_class.constantize.new(user, kase)
  end
end
