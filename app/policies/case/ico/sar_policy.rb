class Case::ICO::SARPolicy < Case::ICO::BasePolicy
  class Scope
    attr_reader :user, :scope


    def initialize(user, scope)
      @user  = user
      @scope = scope
      @policy_scope = Case::SARPolicy::Scope.new(user, scope)
    end

    def resolve
      @policy_scope.resolve
    end
  end

  def show?
    defer_to_existing_policy(Case::SARPolicy, :show?)
  end
end
