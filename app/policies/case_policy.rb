class CasePolicy

  attr_reader :user, :case

  def initialize(user, kase)
    @user = user
    @case = kase
  end

  def can_add_case?
    user.assigner?
  end

  def can_close_case?
    user.assigner? && self.case.responded?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.assigner?
        scope.all
      elsif user.drafter?
        scope.select {|kase| kase.drafter == user }
      else
        nil
      end
    end
  end

end
