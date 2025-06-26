class Case::ICO::SARPolicy < Case::ICO::BasePolicy
  class Scope
    def initialize(user, scope, feature = nil)
      @policy_scope = Case::SARPolicy::Scope.new(user, scope, feature)
    end

    def resolve
      @policy_scope.resolve
    end
  end

  def show?
    defer_to_existing_policy(Case::SARPolicy, :show?)
  end

  def can_set_outcome?
    clear_failed_checks
    user.in?(self.case.approving_team_users)
  end
end
