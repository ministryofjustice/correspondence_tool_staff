class Case::ICO::FOIPolicy < Case::ICO::BasePolicy
  class Scope
    def initialize(user, scope, feature = nil)
      @policy_scope = Case::FOI::StandardPolicy::Scope.new(user, scope, feature)
    end

    def resolve
      @policy_scope.resolve
    end
  end

  def show?
    defer_to_existing_policy(Case::FOI::StandardPolicy, :show?)
  end
end
