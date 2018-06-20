class Case::ICO::BasePolicy < Case::FOI::StandardPolicy

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
        case_ids = Assignment.with_teams(user.approving_team).pluck(:case_id)
        scopes << -> (inner_scope) { inner_scope.where(id: case_ids) }
      end

      if scopes.present?
        final_scope = scopes.shift.call(scope)
        scopes.each do |scope_func|
          final_scope.or(scope_func.call(scope))
        end
        final_scope
      else
        Case::FOI::Standard.none
      end
    end
  end

end
